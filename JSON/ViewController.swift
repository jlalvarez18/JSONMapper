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
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        
        let adapter = JSONAdapter()
        adapter.dateDecodingStrategy = .formatted(dateFormatter)
        
        if let url = Bundle.main.url(forResource: "tweets", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let tweets: [Tweet] = try adapter.decode(data: data)
                
                print(tweets)
            } catch {
                print(error)
            }
        }
    }
}

struct Tweet: JSONMappable {
    let user: User
    let text: String
    let screenName: String
    let createdAt: Date?
    let favorited: Bool

    init(mapper: JSONMapper) throws {
        user = try mapper.decodeValue(forKeyPath: "user")
        screenName = try mapper.decodeValue(forKeyPath: "user.screen_name")
        text = try mapper.decodeValue(forKeyPath: "text")
        createdAt = mapper.decode(forKeyPath: "created_at")
        favorited = try mapper.decodeValue(forKeyPath: "favorited")
    }
}

struct User: JSONMappable {
    let name: String
    let idString: String
    let id: Int
    let createdAt: Date?
    let urls: [URLItem]
    let defaultProfile: Bool
    let followersCount: Int
    let backgroundColor: UIColor?
    
    init(mapper: JSONMapper) throws {
        name = try mapper.decodeValue(forKeyPath: "name")
        idString = try mapper.decodeValue(forKeyPath: "id_str")
        id = try mapper.decodeValue(forKeyPath: "id")
        createdAt = mapper.decode(forKeyPath: "created_at")
        urls = try mapper.decodeValue(forKeyPath: "entities.description.urls")
        defaultProfile = try mapper.decodeValue(forKeyPath: "default_profile")
        followersCount = try mapper.decodeValue(forKeyPath: "followers_count")
        
        backgroundColor = mapper.transform(keyPath: "profile_background_color", block: { (value) -> UIColor? in
            return UIColor.fromHex(hex: value)
        })
    }
}

struct URLItem: JSONMappable {
    let displayURL: URL
    let expandedURL: URL
    let url: URL
    let indices: [Int]
    
    init(mapper: JSONMapper) throws {
        displayURL = try mapper.decodeValue(forKeyPath: "display_url")
        expandedURL = try mapper.decodeValue(forKeyPath: "expanded_url")
        url = try mapper.decodeValue(forKeyPath: "url")
        indices = try mapper.decodeValue(forKeyPath: "indices")
    }
}

