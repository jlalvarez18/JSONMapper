//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

typealias JSONDict = [String: AnyObject]
typealias JSONArray = [JSONDict]

protocol JSONMappable {
    init(mapper: JSONMapper<Self>)
}

enum ValueType {
    case Bool
    case Number
    case String
    case Array
    case Dictionary
    case Null
}

struct JSONDateFormatter {
    private static var formatters: [String: NSDateFormatter] = [:]
    
    static func registerDateFormatter(formatter: NSDateFormatter, withKey key: String) {
        formatters[key] = formatter
    }
    
    static func dateFormatterWith(key: String) -> NSDateFormatter? {
        return formatters[key]
    }
}

class JSONMapper <N: JSONMappable> {
    
    var jsonObject: JSONDict!
    
    init() {}
    
    func map(data: NSData) -> [N]? {
        var error: NSError?
        
        let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: &error)
        
        if json == nil {
            return nil
        }
        
        if let dict = json as? JSONDict {
            return [map(dict)]
        }
        
        if let array = json as? JSONArray {
            return map(array)
        }
        
        return nil
    }
    
    func map(jsonFileURL url: NSURL) -> [N]? {
        if let data = NSData(contentsOfURL: url) {
            return map(data)
        }
        
        return nil
    }
    
    func map(json: JSONDict) -> N {
        jsonObject = json
        
        let object = N(mapper: self)
        
        return object
    }
    
    func map(jsonObjects: JSONArray) -> [N] {
        let results = jsonObjects.map({ (json: JSONDict) -> N in
            return self.map(json)
        })
        
        return results
    }
    
    func valueTypeFor(key: String) -> ValueType {
        if let value: AnyObject = valueFor(key) {
            switch value {
            case let number as NSNumber:
                if number.isBool() {
                    return .Bool
                } else {
                    return .Number
                }
            case let string as String:
                return .String
            case let array as [AnyObject]:
                return .Array
            case let dict as [String: AnyObject]:
                return .Dictionary
            default:
                return .Null
            }
        }
        
        return .Null
    }
    
    subscript(key: String) -> AnyObject? {
        return valueFor(key)
    }
}

private extension JSONMapper {
    
    func valueFor(key: String) -> AnyObject? {
        return valueFor(key.componentsSeparatedByString("."), dictionary: jsonObject)
    }
    
    func valueFor(keys: [String], dictionary: JSONDict) -> AnyObject? {
        if keys.isEmpty {
            return nil
        }
        
        if let object: AnyObject = dictionary[keys.first!] {
            switch object {
            case is NSNull:
                return nil
            case let dict as JSONDict where keys.count > 1:
                let tail = Array(keys[1..<keys.count])
                
                return valueFor(tail, dictionary: dict)
            default:
                return object
            }
        }
        
        return nil
    }
}

// MARK: NSDate

extension JSONMapper {

    typealias DateTransformerFromInt = (value: Int) -> NSDate?
    typealias DateTransformerFromString = (value: String) -> NSDate?
    
    func dateFromIntFor(key: String, transform: DateTransformerFromInt) -> NSDate? {
        if let value = intFor(key) {
            return transform(value: value)
        }
        
        return nil
    }
    
    func dateFromStringFor(key: String, transform: DateTransformerFromString) -> NSDate? {
        if let value = stringFor(key) {
            return transform(value: value)
        }
        
        return nil
    }
}

// MARK: URL

extension JSONMapper {
    
    func urlFrom(key: String) -> NSURL? {
        if let value = stringFor(key) {
            return NSURL(string: value)
        }
        
        return nil
    }
}

// MARK: String

extension JSONMapper {
    
    func stringFor(key: String) -> String? {
        return valueFor(key) as? String
    }
    
    func stringValueFor(key: String) -> String {
        if let value = stringFor(key) {
            return value
        }
        
        return ""
    }
}

// MARK: Int

extension JSONMapper {
    
    func intFor(key: String) -> Int? {
        return valueFor(key) as? Int
    }
    
    func intValueFor(key: String) -> Int {
        if let value = intFor(key) {
            return value
        }
        
        return 0
    }
}

// MARK: Bool

extension JSONMapper {
    
    func boolFor(key: String) -> Bool? {
        return valueFor(key) as? Bool
    }
    
    func boolValueFor(key: String) -> Bool {
        if let value = boolFor(key) {
            return value
        }
        
        return false
    }
}

// MARK: Double

extension JSONMapper {
    
    func doubleFor(key: String) -> Double? {
        return valueFor(key) as? Double
    }
    
    func doubleValueFor(key: String) -> Double {
        if let value = doubleFor(key) {
            return value
        }
        
        return 0.0
    }
}

// MARK: Float

extension JSONMapper {
    
    func floatFor(key: String) -> Float? {
        return valueFor(key) as? Float
    }
    
    func floatValueFor(key: String) -> Float {
        if let value = floatFor(key) {
            return value
        }
        
        return 0.0
    }
}

// MARK: Array

extension JSONMapper {
    
    func arrayFor(key: String) -> Array<AnyObject>? {
        return valueFor(key) as? Array<AnyObject>
    }
    
    func arrayValueFor(key: String) -> Array<AnyObject> {
        if let value = arrayFor(key) {
            return value
        }
        
        return []
    }
}

// MARK: Dictionary

extension JSONMapper {
    
    func dictionaryFor(key: String) -> JSONDict? {
        return valueFor(key) as? JSONDict
    }
    
    func dictionaryValueFor(key: String) -> JSONDict {
        if let value = dictionaryFor(key) {
            return value
        }
        
        return [:]
    }
}

// MARK: Object: JSONMappable

extension JSONMapper {
    
    func objectArrayFor<T: JSONMappable>(key: String) -> [T]? {
        if let arrayValues = valueFor(key) as? JSONArray {
            let mapper = JSONMapper<T>()
            
            let newValues = arrayValues.map({ (dict: JSONDict) -> T in
                return mapper.map(dict)
            })
            
            return newValues
        }
        
        return nil
    }
    
    func objectArrayValueFor<T: JSONMappable>(key: String) -> [T] {
        if let values: [T] = objectArrayFor(key) {
            return values
        }
        
        return []
    }
    
    func objectFor<T: JSONMappable>(key: String) -> T? {
        if let dict = dictionaryFor(key) {
            let mapper = JSONMapper<T>()
            
            let object = mapper.map(dict)
            
            return object
        }
        
        return nil
    }
}

// MARK: Transforms

extension String {
    func transform<T>(block: (value: String) -> T?) -> T? {
        return block(value: self)
    }
}

extension Int {
    func transform<T>(block: (value: Int) -> T?) -> T? {
        return block(value: self)
    }
}

extension Double {
    func transform<T>(block: (value: Double) -> T?) -> T? {
        return block(value: self)
    }
}

extension Float {
    func transform<T>(block: (value: Float) -> T?) -> T? {
        return block(value: self)
    }
}


