//
//  ServerSelectionView.swift
//  ABJC
//
//  Created by Noah Kamara on 26.03.21.
//

import SwiftUI

extension AuthView {
    struct ServerSelectionView: View {
        
        /// SessionStore EnvironmentObject
        @EnvironmentObject var session: SessionStore
        
        /// Servers Discovered By ServerLookup
        @State var servers: [ServerLocator.ServerLookupResponse] = []
        
        @State var searching = false
        
        /// ServerLocator
        private let locator: ServerLocator = ServerLocator()
        
        var body: some View {
            
            GeometryReader { geometry in
                HStack {
                    VStack {
                        Image("logoWithText")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(0.75)
                    }
                    .frame(width: geometry.size.width * 1/2)
                    
                    VStack(alignment: .center) {
                        
                        VStack {
                            HStack(spacing: 5) {
                                Spacer()
                                    .frame(width: 200)
                                Text("authView.serverSelection.title")
                                    .font(.title2).bold()
                                ProgressView()
                                    .frame(width: 200)
                                    .hidden(!searching)
                                
                            }
                            
                            Group {
                                ScrollView {
                                    VStack(spacing: 10) {
                                        
                                        if self.servers.count > 0 {
                                            ForEach(self.servers, id:\.id) { server in
                                                NavigationLink(
                                                    destination: CredentialEntryView(server.host, Int(server.port), nil))
                                                {
                                                    ServerCardView(server)
                                                }
                                                .padding()
                                            }
                                        }
                                        
                                        NavigationLink(destination: ManualView())
                                        {
                                            ServerCardView("authView.serverSelection.manual.label",
                                                           "authView.serverSelection.manual.descr")
                                        }
                                        .padding()
                                        
                                    }
                                }
                                
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        
                    }
                    .frame(width: geometry.size.width * 1/2)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: Color.backgroundGradient),
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all))
            .onAppear(perform: discover)
            //                .onLongPressGesture {
            //                    DispatchQueue.main.async {
            //                        session.preferences.isDebugEnabled.toggle()
            //                        if session.preferences.isDebugEnabled {
            //                            session.alert = AlertError("pref.debugmode.title", "pref.debugmode.enabled")
            //                        } else {
            //                            session.alert = AlertError("pref.debugmode.title", "pref.debugmode.disabled")
            //                        }
            //                    }
            //                }
        }
        
        /// Discover Servers
        func discover() {
            searching = true
            
            // Timeout after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.searching = false
            }
            
            locator.locateServer { [self] (server) in
                if let server = server, !servers.contains(server) {
                    servers.append(server)
                }
                searching = false
            }
        }
    }
    
    struct ServerSelectionView_Previews: PreviewProvider {
        static var previews: some View {
            ServerSelectionView()
        }
    }
}
