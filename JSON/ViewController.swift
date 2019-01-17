//
//  ViewController.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

struct Tweet: Mappable {
    let user: User
    let text: String
    let screenName: String
    let createdAt: Date
    let favorited: Bool
    let language: Language?
    let urlItems: [URLItem]
    
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
    }
    
    init(mapper: Mapper) throws {
        language = mapper.decode(forKeyPath: Keys.language)
        user = try mapper.decodeValue(forKeyPath: Keys.user)
        screenName = try mapper.decodeValue(forKeyPath: "user.screen_name")
        text = try mapper.decodeValue(forKeyPath: Keys.text)
        createdAt = try mapper.decodeValue(forKeyPath: Keys.createdAt)
        favorited = try mapper.decodeValue(forKeyPath: Keys.favorited)
        urlItems = try mapper.decodeValue(forKeyPath: ["entities", "urls"], decoder: JSONDecoder())
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
    
    init(mapper: Mapper) throws {
        name = try mapper.decodeValue(forKeyPath: "name")
        idString = try mapper.decodeValue(forKeyPath: "id_str")
        id = try mapper.decodeValue(forKeyPath: "id")
        createdAt = try mapper.decodeValue(forKeyPath: "created_at")
        urlItems = try mapper.decodeValue(forKeyPath: ["entities", "description", "urls"], decoder: JSONDecoder())
        defaultProfile = try mapper.decodeValue(forKeyPath: "default_profile")
        followersCount = try mapper.decodeValue(forKeyPath: "followers_count")
        url = mapper.decode(forKeyPath: "url")
        description = try mapper.decodeValue(forKeyPath: "description")
        
        backgroundColor = mapper.transform(keyPath: "profile_background_color", block: { (value) -> UIColor in
            return UIColor.fromHex(hex: value)
        })
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
    
    //    init(mapper: Mapper) throws {
    //        displayUrl = try mapper.decodeValue(forKeyPath: "display_url")
    //        expandedUrl = try mapper.decodeValue(forKeyPath: "expanded_url")
    //        url = try mapper.decodeValue(forKeyPath: "url")
    //        indices = try mapper.decodeValue(forKeyPath: "indices")
    //    }
}
