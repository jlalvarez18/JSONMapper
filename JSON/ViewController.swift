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
                
                let desc = deepDescription(tweets)
                print(desc)
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
    
    let userScreenName: UserScreenName?
    
    enum UserScreenName: String, JSONMappable {
        case healthRanger = "HealthRanger"
        case dhh = "dhh"
        case randPaul = "SenRandPaul"
        case armstrong = "StrongEconomics"
    }
    
    enum Keys: String, JSONKey {
        case user
        case screenName = "user.screen_name"
        case text
        case createdAt = "created_at"
        case favorited = "favorited"
    }

    init(mapper: JSONMapper) throws {
        userScreenName = mapper.decode(forKeyPath: Keys.screenName)
        user = try mapper.decodeValue(forKeyPath: Keys.user)
        screenName = try mapper.decodeValue(forKeyPath: Keys.screenName)
        text = try mapper.decodeValue(forKeyPath: Keys.text)
        createdAt = mapper.decode(forKeyPath: Keys.createdAt)
        favorited = try mapper.decodeValue(forKeyPath: Keys.favorited)
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
        urls = try mapper.decodeValue(forKeyPath: "entities", "description", "urls")
        defaultProfile = try mapper.decodeValue(forKeyPath: "default_profile")
        followersCount = try mapper.decodeValue(forKeyPath: "followers_count")
        
        backgroundColor = try mapper.transform(keyPath: "profile_background_color", block: { (value) -> UIColor? in
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

func deepDescription(_ any: Any) -> String {
    guard let any = deepUnwrap(any) else {
        return "nil"
    }
    
    if any is Void {
        return "Void"
    }
    
    if let int = any as? Int {
        return String(int)
    } else if let double = any as? Double {
        return String(double)
    } else if let float = any as? Float {
        return String(float)
    } else if let bool = any as? Bool {
        return String(bool)
    } else if let string = any as? String {
        return "\"\(string)\""
    }
    
    let indentedString: (String) -> String = {
        $0.components(separatedBy: .newlines).map { $0.isEmpty ? "" : "\r    \($0)" }.joined(separator: "")
    }
    
    let mirror = Mirror(reflecting: any)
    
    let properties = Array(mirror.children)
    
    guard let displayStyle = mirror.displayStyle else {
        return String(describing: any)
    }
    
    switch displayStyle {
    case .tuple:
        if properties.count == 0 { return "()" }
        
        var string = "("
        
        for (index, property) in properties.enumerated() {
            if property.label!.first! == "." {
                string += deepDescription(property.value)
            } else {
                string += "\(property.label!): \(deepDescription(property.value))"
            }
            
            string += (index < properties.count - 1 ? ", " : "")
        }
        
        return string + ")"
        
    case .collection, .set:
        if properties.count == 0 { return "[]" }
        
        var string = "["
        
        for (index, property) in properties.enumerated() {
            string += indentedString(deepDescription(property.value) + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
        
    case .dictionary:
        if properties.count == 0 { return "[:]" }
        
        var string = "["
        
        for (index, property) in properties.enumerated() {
            let pair = Array(Mirror(reflecting: property.value).children)
            
            string += indentedString("\(deepDescription(pair[0].value)): \(deepDescription(pair[1].value))" + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
        
    case .enum:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        if properties.count == 0 { return "\(mirror.subjectType)." + String(describing: any) }
        
        var string = "\(mirror.subjectType).\(properties.first!.label!)"
        
        let associatedValueString = deepDescription(properties.first!.value)
        
        if associatedValueString.first! == "(" {
            string += associatedValueString
        } else {
            string += "(\(associatedValueString))"
        }
        
        return string
        
    case .struct, .class:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        if properties.count == 0 { return String(describing: any) }
        
        var string = "<\(mirror.subjectType)"
        
        if displayStyle == .class {
            string += ": \(Unmanaged<AnyObject>.passUnretained(any as AnyObject).toOpaque())"
        }
        
        string += "> {"
        
        for (index, property) in properties.enumerated() {
            string += indentedString("\(property.label!): \(deepDescription(property.value))" + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r}"
        
    case .optional:
        fatalError("deepUnwrap must have failed...")
    }
}

func deepUnwrap(_ any: Any) -> Any? {
    let mirror = Mirror(reflecting: any)
    
    if mirror.displayStyle != .optional {
        return any
    }
    
    if let child = mirror.children.first, child.label == "some" {
        return deepUnwrap(child.value)
    }
    
    return nil
}
