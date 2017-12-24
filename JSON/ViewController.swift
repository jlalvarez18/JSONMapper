//
//  ViewController.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        
        JSONDateFormatter.registerDateFormatter(formatter: dateFormatter, withKey: "TweetDateFormatter")
        
        if let jsonURL = Bundle.main.url(forResource: "tweets", withExtension: "json") {
            do {
                let tweets = try JSONAdapter<Tweet>.objectsFromJSONFile(url: jsonURL)
                
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

    init(mapper: JSONMapper) {
        user = mapper.objectFor(keyPath: "user")!
        screenName = mapper.stringValueFor(keyPath: "user.screen_name")
        text = mapper.stringValueFor(keyPath: "text")
        createdAt = mapper.dateFromStringFor(keyPath: "created_at", withFormatterKey: "TweetDateFormatter")
        favorited = mapper.boolValueFor(keyPath: "favorited")
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
    
    init(mapper: JSONMapper) {
        name = mapper.stringValueFor(keyPath: "name")
        idString = mapper.stringValueFor(keyPath: "id_str")
        id = mapper.intValueFor(keyPath: "id")
        urls = mapper.objectArrayValueFor(keyPath: "entities.description.urls", defaultValue: [])
        defaultProfile = mapper.boolValueFor(keyPath: "default_profile")
        followersCount = mapper.intValueFor(keyPath: "followers_count")
        
        backgroundColor = mapper.transform(keyPath: "profile_background_color", block: { (value) -> UIColor? in
            return UIColor.fromHex(hex: value)
        })
        
        createdAt = mapper.dateFromStringFor(keyPath: "created_at", withFormatterKey: "TweetDateFormatter")
    }
}

struct URLItem: JSONMappable {
    let displayURL: URL
    let expandedURL: URL
    let url: URL
    let indices: Set<Int>
    
    init(mapper: JSONMapper) {
        displayURL = mapper.urlValueFrom(keyPath: "display_url")
        expandedURL = mapper.urlValueFrom(keyPath: "expanded_url")
        url = mapper.urlValueFrom(keyPath: "url")
        indices = mapper.setValueFor(keyPath: "indices")
    }
}

