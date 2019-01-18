//
//  Tweet.swift
//  JSON
//
//  Created by Juan Alvarez on 1/18/19.
//  Copyright © 2019 Alvarez Productions. All rights reserved.
//

import Foundation
import UIKit

struct Tweet: Mappable {
    let user: User
    let text: String
    let screenName: String
    let createdAt: Date
    let favorited: Bool
    let language: Language?
    let urlItems: [URLItem]
    let replyToStatus: Int?
    
    enum Language: String, Mappable {
        case english = "en"
        case french = "fr"
        case spanish = "es"
    }
    
    enum Keys: String, Key {
        case user
        case text
        case createdAt
        case favorited
        case language = "lang"
        case urlItems = "entities.urls"
        case replayToStatusId = "in_reply_to_status_id"
    }
    
    init(mapper: Mapper) throws {
        let container = try mapper.keyedMapperValue()
        
        language = container.decode(forKeyPath: Keys.language)
        user = try container.decodeValue(forKeyPath: Keys.user)
        screenName = try container.decodeValue(forKeyPath: ["user", "screen_name"])
        text = try container.decodeValue(forKeyPath: Keys.text)
        createdAt = try container.decodeValue(forKeyPath: Keys.createdAt)
        favorited = try container.decodeValue(forKeyPath: Keys.favorited)
        urlItems = try container.decodeValue(forKeyPath: Keys.urlItems, decoder: JSONDecoder())
        replyToStatus = container.decode(forKeyPath: Keys.replayToStatusId)
    }
}

struct User: Mappable {
    let name: String
    let idString: String
    let id: Int
    let createdAt: Date
    let url: URL?
    let urlItems: [URLItem]
    let defaultProfile: Bool
    let followersCount: Int
    let description: String
    let backgroundColor: UIColor?
    
    enum Keys: String, Key {
        case idString = "id_str"
        case createdAt = "created_at"
        case defaultProfile = "default_profile"
        case followersCount = "followers_count"
        case description
        case backgroundColor = "profile_background_color"
    }
    
    init(mapper: Mapper) throws {
        let container = try mapper.keyedMapperValue()
        
        name = try container.decodeValue(forKeyPath: "name")
        idString = try container.decodeValue(forKeyPath: Keys.idString)
        id = try container.decodeValue(forKeyPath: "id")
        createdAt = try container.decodeValue(forKeyPath: Keys.createdAt)
        urlItems = try container.decodeValue(forKeyPath: ["entities", "description", "urls"], decoder: JSONDecoder())
        defaultProfile = try container.decodeValue(forKeyPath: Keys.defaultProfile)
        followersCount = try container.decodeValue(forKeyPath: Keys.followersCount)
        url = container.decode(forKeyPath: "url")
        description = try container.decodeValue(forKeyPath: Keys.description)
        
        backgroundColor = container.transform(forKeyPath: Keys.backgroundColor) { value in
            return UIColor.fromHex(hex: value)
        }
    }
}

struct URLItem: Decodable {
    let displayURL: String
    let expandedURL: URL
    let url: URL
    let indices: [Int]
    
    enum CodingKeys: String, CodingKey {
        case displayURL = "display_url"
        case expandedURL = "expanded_url"
        case url
        case indices
    }
}
