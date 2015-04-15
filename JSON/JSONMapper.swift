//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

public typealias JSONDict = [String: AnyObject]
public typealias JSONArray = [JSONDict]

public protocol JSONMappable {
    init(mapper: JSONMapper<Self>)
}

public enum ValueType {
    case Bool
    case Number
    case String
    case Array
    case Dictionary
    case Null
}

public struct JSONDateFormatter {
    private static var formatters: [String: NSDateFormatter] = [:]
    
    public static func registerDateFormatter(formatter: NSDateFormatter, withKey key: String) {
        formatters[key] = formatter
    }
    
    public static func dateFormatterWith(key: String) -> NSDateFormatter? {
        return formatters[key]
    }
}

public class JSONMapper <N: JSONMappable> {
    
    var jsonObject: JSONDict!
    
    public init() {}
    
    public func map(data: NSData) -> [N]? {
        var error: NSError?
        
        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: &error) {
            return map(json)
        }
        
        return nil
    }
    
    public func map(jsonFileURL url: NSURL) -> [N]? {
        if let data = NSData(contentsOfURL: url) {
            return map(data)
        }
        
        return nil
    }
    
    public func map(json: JSONDict) -> N {
        jsonObject = json
        
        let object = N(mapper: self)
        
        return object
    }
    
    public func map(jsonObjects: JSONArray) -> [N] {
        let results = jsonObjects.map({ (json: JSONDict) -> N in
            return self.map(json)
        })
        
        return results
    }
    
    public func map(array: [AnyObject]) -> [N]? {
        if let array = array as? JSONArray {
            return self.map(array)
        }
        
        return nil
    }
    
    public func map(object: AnyObject) -> [N]? {
        if let dict = object as? JSONDict {
            return [map(dict)]
        }
        
        if let array = object as? JSONArray {
            return map(array)
        }
        
        return nil
    }
    
    public func valueTypeFor(key: String) -> ValueType {
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
    
    public subscript(key: String) -> AnyObject? {
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
    
    public typealias DateTransformerFromInt = (value: Int) -> NSDate?
    public typealias DateTransformerFromString = (value: String) -> NSDate?
    
    public func dateFromIntFor(key: String, transform: DateTransformerFromInt) -> NSDate? {
        if let value = intFor(key) {
            return transform(value: value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(key: String, transform: DateTransformerFromString) -> NSDate? {
        if let value = stringFor(key) {
            return transform(value: value)
        }
        
        return nil
    }
}

// MARK: URL

extension JSONMapper {
    
    public func urlFrom(key: String) -> NSURL? {
        if let value = stringFor(key) {
            return NSURL(string: value)
        }
        
        return nil
    }
}

// MARK: String

extension JSONMapper {
    
    public func stringFor(key: String) -> String? {
        return valueFor(key) as? String
    }
    
    public func stringValueFor(key: String) -> String {
        if let value = stringFor(key) {
            return value
        }
        
        return ""
    }
}

// MARK: Int

extension JSONMapper {
    
    public func intFor(key: String) -> Int? {
        return valueFor(key) as? Int
    }
    
    public func intValueFor(key: String) -> Int {
        if let value = intFor(key) {
            return value
        }
        
        return 0
    }
}

// MARK: Bool

extension JSONMapper {
    
    public func boolFor(key: String) -> Bool? {
        return valueFor(key) as? Bool
    }
    
    public func boolValueFor(key: String) -> Bool {
        if let value = boolFor(key) {
            return value
        }
        
        return false
    }
}

// MARK: Double

extension JSONMapper {
    
    public func doubleFor(key: String) -> Double? {
        return valueFor(key) as? Double
    }
    
    public func doubleValueFor(key: String) -> Double {
        if let value = doubleFor(key) {
            return value
        }
        
        return 0.0
    }
}

// MARK: Float

extension JSONMapper {
    
    public func floatFor(key: String) -> Float? {
        return valueFor(key) as? Float
    }
    
    public func floatValueFor(key: String) -> Float {
        if let value = floatFor(key) {
            return value
        }
        
        return 0.0
    }
}

// MARK: Array

extension JSONMapper {
    
    public func arrayFor(key: String) -> Array<AnyObject>? {
        return valueFor(key) as? Array<AnyObject>
    }
    
    public func arrayValueFor(key: String) -> Array<AnyObject> {
        if let value = arrayFor(key) {
            return value
        }
        
        return []
    }
}

// MARK: Dictionary

extension JSONMapper {
    
    public func dictionaryFor(key: String) -> JSONDict? {
        return valueFor(key) as? JSONDict
    }
    
    public func dictionaryValueFor(key: String) -> JSONDict {
        if let value = dictionaryFor(key) {
            return value
        }
        
        return [:]
    }
}

// MARK: Object: JSONMappable

extension JSONMapper {
    
    public func objectArrayFor<T: JSONMappable>(key: String) -> [T]? {
        if let arrayValues = valueFor(key) as? JSONArray {
            let mapper = JSONMapper<T>()
            
            let newValues = arrayValues.map({ (dict: JSONDict) -> T in
                return mapper.map(dict)
            })
            
            return newValues
        }
        
        return nil
    }
    
    public func objectArrayValueFor<T: JSONMappable>(key: String) -> [T] {
        if let values: [T] = objectArrayFor(key) {
            return values
        }
        
        return []
    }
    
    public func objectFor<T: JSONMappable>(key: String) -> T? {
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
    public func transform<T>(block: (value: String) -> T?) -> T? {
        return block(value: self)
    }
}

extension Int {
    public func transform<T>(block: (value: Int) -> T?) -> T? {
        return block(value: self)
    }
}

extension Double {
    public func transform<T>(block: (value: Double) -> T?) -> T? {
        return block(value: self)
    }
}

extension Float {
    func transform<T>(block: (value: Float) -> T?) -> T? {
        return block(value: self)
    }
}
