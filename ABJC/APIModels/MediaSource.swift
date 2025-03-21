//
//  MediaSource.swift
//  ABJC
//
//  Created by Noah Kamara on 03.04.21.
//

import Foundation

extension APIModels {
    public struct MediaSource: Codable {
        public var id: String
        public var type: String
        public var container: String
        
        public var canPlay: Bool {
            print(type, container)
            return container == "mp4"
        }
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case type = "Type"
            case container = "Container"
        }
    }
}
