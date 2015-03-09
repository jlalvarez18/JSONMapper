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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        
        JSONDateFormatter.registerDateFormatter(dateFormatter, withKey: "TweetDateFormatter")
        
        let jsonURL = NSBundle.mainBundle().URLForResource("tweets", withExtension: "json")
        let jsonData = NSData(contentsOfURL: jsonURL!)
        
        var error: NSError?
        if let json = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.allZeros, error: &error) as? JSONArray {
            let mapper = JSONMapper<Tweet>()
            
            let tweets = mapper.map(json)
            
            println(tweets)
        } else {
            println(error)
        }
    }
}

struct Tweet: JSONMappable {
    let user: User
    let text: String
    let screenName: String
    let createdAt: NSDate?
    let favorited: Bool

    init(mapper: JSONMapper<Tweet>) {
        user = mapper.objectFor("user")!
        screenName = mapper.stringValueFor("user.screen_name")
        text = mapper.stringValueFor("text")
        favorited = mapper.boolValueFor("favorited")
        
        let dateFormatter = JSONDateFormatter.dateFormatterWith("TweetDateFormatter")!
        
        createdAt = mapper.dateFromStringFor("created_at", transform: { (value) -> NSDate? in
            return dateFormatter.dateFromString(value)
        })
    }
}

struct User: JSONMappable {
    let name: String
    let idString: String
    let id: Int
    let createdAt: NSDate?
    let urls: [URL]?
    let defaultProfile: Bool
    let followersCount: Int
    let backgroundColor: UIColor?
    
    init(mapper: JSONMapper<User>) {
        name = mapper.stringValueFor("name")
        idString = mapper.stringValueFor("id_str")
        id = mapper.intValueFor("id")
        urls = mapper.objectArrayValueFor("entities.description.urls")
        defaultProfile = mapper.boolValueFor("default_profile")
        followersCount = mapper.intValueFor("followers_count")
        
        backgroundColor = mapper.stringFor("profile_background_color")?.transform({ (value) -> UIColor? in
            return UIColor.fromHex(value)
        })
        
        let dateFormatter = JSONDateFormatter.dateFormatterWith("TweetDateFormatter")!
        
        createdAt = mapper.dateFromStringFor("created_at", transform: { (value) -> NSDate? in
            return dateFormatter.dateFromString(value)
        })
    }
}

struct URL: JSONMappable {
    let displayURL: NSURL?
    let expandedURL: NSURL?
    let url: NSURL?
    
    init(mapper: JSONMapper<URL>) {
        displayURL = mapper.urlFrom("display_url")
        expandedURL = mapper.urlFrom("expanded_url")
        url = mapper.urlFrom("url")
    }
}

extension UIColor {
    public class func fromRGB(r: Int, _ g: Int, _ b: Int) -> UIColor {
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1)
    }
    
    public class func fromHex(hex: String) -> UIColor {
        var str = hex.uppercaseString
        
        if str.hasPrefix("#") {
            str = str.substring(1..<count(str))!
        }
        
        if count(str) != 6 {
            fatalError("hex must have 6 charachters: \(hex)")
        }
        
        var r: UInt32 = 0
        var g: UInt32 = 0
        var b: UInt32 = 0
        
        NSScanner(string: str.substring(0...1)!).scanHexInt(&r)
        NSScanner(string: str.substring(2...3)!).scanHexInt(&g)
        NSScanner(string: str.substring(4...5)!).scanHexInt(&b)
        
        return fromRGB(Int(r), Int(g), Int(b))
    }
}

extension String {
    func substring(range: Range<Int>) -> String? {
        if range.startIndex < 0 || range.endIndex > count(self) {
            return nil
        }
        
        let range = Range(start: advance(startIndex, range.startIndex), end: advance(startIndex, range.endIndex))
        
        return self[range]
    }
}

