//
//  SessionStore.swift
//  ABJC
//
//  Created by Noah Kamara on 26.03.21.
//

import Foundation
import SwiftUI
import os

class SessionStore: ObservableObject {
    /// Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SESSION")
        
    /// Jellyfin Object
    @Published public var jellyfin: Jellyfin? = nil
    
    /// Preference Store
    @Published public var preferences: PreferenceStore = PreferenceStore()
    
    /// Focus Item
    @Published public var itemFocus: APIModels.MediaItem? = nil
    @Published public var prevFocus: APIModels.MediaItem? = nil
    
    /// Playing Item
    @Published public var itemPlaying: PlayItem? = nil
    
    /// Pending Alert
    @Published var alert: Alert? = nil
    
    /// Cached Items
    @Published var items: [APIModels.MediaItem] = []
    
    
    /// Loads Credentials and tries to authenticate with them
    /// - Parameter completion: Boolean value indicating success
    public func loadCredentials(_ completion: @escaping (Bool) -> Void = { _ in}) {
        guard let data = Keychain.load(key: "credentials") else {
            completion(false)
            return
        }
        do {
            let jellyfin = try JSONDecoder().decode(Jellyfin.self, from: data)
            API.currentUser(jellyfin) { (result) in
                switch result {
                    case .success(_ ):
                        self.logger.info("[CREDENTIALS] successfully authenticated with stored credentials")
                        self.setJellyfin(jellyfin)
                        completion(true)
                        
                    case .failure(let error):
                        self.logger.info("[CREDENTIALS] failed to authenticate with stored credentials")
                        self.setAlert(
                            .auth,
                            "failed",
                            "\(jellyfin.server.https ? "(HTTPS)":"") \(jellyfin.user.userId)@\(jellyfin.server.host):\(jellyfin.server.port)",
                            error
                        )
                        completion(false)
                }
            }
        } catch {
            print(error)
            self.logger.info("[CREDENTIALS] unable to load credentials")
            completion(false)
        }
    }
    
    
    /// Clears Stored Credentials
    public func clearCredentials() {
        Keychain.clear(key: "credentials")
    }
    
    
    /// Stores Credentials in Keychain
    public func storeCredentials() {
        do {
            let data = try JSONEncoder().encode(self.jellyfin)
            _ = Keychain.save(key: "credentials", data: data)
            self.logger.info("[CREDENTIALS] successfully stored credentials")
        } catch {
            print(error)
            self.logger.info("[CREDENTIALS] failed to store credentials")
        }
    }
    
    
    /// Sets the focus of the application
    /// - Parameter item: Media Item (Movie, Series)
    public func setFocus(_ item: APIModels.MediaItem) {
        DispatchQueue.main.async {
            self.itemFocus = item
        }
    }
    
    
    /// Restores previous focus
    public func restoreFocus() {
        if prevFocus != nil {
            DispatchQueue.main.async {
                self.itemFocus = self.prevFocus
                self.prevFocus = nil
            }
        }
    }
    
    
    /// Sets play item
    /// - Parameter item: Playable Media Item
    public func setPlayItem(_ item: PlayItem) {
        DispatchQueue.main.async {
            self.prevFocus = self.itemFocus
            self.itemPlaying = item
            self.itemFocus = nil
        }
    }
    
    
    /// Set Jellyfin Object
    /// - Parameter jellyfin: Jellyfin Object
    public func setJellyfin(_ jellyfin: Jellyfin) {
        DispatchQueue.main.async {
            self.jellyfin = jellyfin
            self.storeCredentials()
        }
    }
    
    
    /// Logs the user out of the application & clears their credentials from the Keychain
    public func logout() {
        self.clearCredentials()
        DispatchQueue.main.async {
            self.jellyfin = nil
        }
    }
    
    
    /// Set Alert
    /// - Parameters:
    ///   - alertType: <#alertType description#>
    ///   - localized: <#localized description#>
    ///   - debug: <#debug description#>
    ///   - error: <#error description#>
    public func setAlert(_ alertType: Alert.AlertType, _ localized: String, _ debug: String, _ error: Error?) {
        logger.warning("[\(alertType.rawValue)], \(debug), \(error != nil ? error!.localizedDescription : "NO ERROR")")
        DispatchQueue.main.async {
            self.alert = Alert(title: alertType.localized, description: LocalizedStringKey("alerts." + alertType.rawValue + "." + localized))
        }
    }
    
    /// Reload Items / Refetch from API
    public func reloadItems() {
        guard let jellyfin = jellyfin else { return }
        
        API.items(jellyfin) { result in
            switch result {
                case .success(let items):
                    DispatchQueue.main.async {
                        self.items.append(contentsOf: items.filter({ !self.items.contains($0) }))
                    }
                case .failure(let error):
                    self.setAlert(.api, "Could not fetch Data from Server", "API.items failed", error)
            }
        }
    }
}

extension SessionStore {
    struct Alert: Identifiable {
        var id: String = Date().description
        var title: LocalizedStringKey
        var description: LocalizedStringKey
        
        enum AlertType: String {
            case auth = "auth"
            case api = "api"
            case playback = "playback"
            
            var logInfo: String {
                return self.rawValue.uppercased()
            }
            
            var localized: LocalizedStringKey {
                return LocalizedStringKey("alerts.\(self.rawValue).title")
            }
        }
    }
}
