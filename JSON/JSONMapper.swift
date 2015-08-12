//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

public typealias JSONDict = NSDictionary
public typealias JSONArray = [JSONDict]

public protocol JSONMappable {
    init(mapper: JSONMapper)
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

public class JSONAdapter <N: JSONMappable> {
    
    private init() {}
    
    public class func objectFromJSONDictionary(dict: JSONDict) -> N {
        let mapper = JSONMapper(dictionary: dict)
        let object = N(mapper: mapper)
        
        return object
    }
    
    public class func objectsFromJSONArray(array: JSONArray) -> [N] {
        let results = array.map({ (json: JSONDict) -> N in
            return self.objectFromJSONDictionary(json)
        })
        
        return results
    }
    
    public class func objectsFromJSONFile(url: NSURL) -> [N]? {
        if let data = NSData(contentsOfURL: url) {
            return objectsFromJSONData(data)
        }
        
        return nil
    }
    
    public class func objectsFromJSONData(data: NSData) -> [N]? {
        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: nil) {
            if let dict = json as? JSONDict {
                return [objectFromJSONDictionary(dict)]
            }
            
            if let array = json as? JSONArray {
                return objectsFromJSONArray(array)
            }
        }
        
        return nil
    }
    
    public class func objectsFrom(array: [AnyObject]) -> [N]? {
        if let array = array as? JSONArray {
            return objectsFromJSONArray(array)
        }
        
        return nil
    }
    
    public class func objectsValueFrom(array: [AnyObject]) -> [N] {
        if let array = objectsFrom(array) {
            return array
        }
        
        return []
    }
    
    public class func objectFrom(object: AnyObject) -> N? {
        if let dict = object as? JSONDict {
            return objectFromJSONDictionary(dict)
        }
        
        return nil
    }
}

public final class JSONMapper {
    
    public var rawJSONDictionary: JSONDict
    
    public init(dictionary: JSONDict) {
        rawJSONDictionary = dictionary
    }
    
    public subscript(keyPath: String) -> AnyObject? {
        return rawJSONDictionary.valueForKeyPath(keyPath)
    }
}

extension JSONMapper: DictionaryLiteralConvertible {
    public typealias Key = String
    public typealias Value = AnyObject
    
    public convenience init(dictionaryLiteral elements: (Key, Value)...) {
        var dictionary = [String: AnyObject]()
        
        for (key_, value) in elements {
            dictionary[key_] = value
        }
        
        self.init(dictionary: dictionary)
    }
}

// MARK: String

extension JSONMapper {
    
    public func stringFor(keyPath: String) -> String? {
        return rawJSONDictionary.valueForKeyPath(keyPath) as? String
    }
    
    public func stringValueFor(keyPath: String) -> String {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! String
    }
    
    public func stringValueFor(keyPath: String, defaultValue: String) -> String {
        return stringFor(keyPath) ?? defaultValue
    }
}

// MARK: Int

extension JSONMapper {
    
    public func intFor(keyPath: String) -> Int? {
        return rawJSONDictionary.valueForKeyPath(keyPath) as? Int
    }
    
    public func intValueFor(keyPath: String) -> Int {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! Int
    }
    
    public func intValueFor(keyPath: String, defaultValue: Int) -> Int {
        return intFor(keyPath) ?? defaultValue
    }
}

// MARK: Bool

extension JSONMapper {
    
    public func boolFor(keyPath: String) -> Bool? {
        if let value = rawJSONDictionary.valueForKeyPath(keyPath) as? Bool {
            return value
        }
        
        if let value = rawJSONDictionary.valueForKeyPath(keyPath) as? String {
            switch value.lowercaseString {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        }
        
        return nil
    }
    
    public func boolValueFor(keyPath: String) -> Bool {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! Bool
    }
    
    public func boolValueFor(keyPath: String, defaultValue: Bool) -> Bool {
        return boolFor(keyPath) ?? defaultValue
    }
}

// MARK: Double

extension JSONMapper {
    
    public func doubleFor(keyPath: String) -> Double? {
        return rawJSONDictionary.valueForKeyPath(keyPath) as? Double
    }
    
    public func doubleValueFor(keyPath: String) -> Double {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! Double
    }
    
    public func doubleValueFor(keyPath: String, defaultValue: Double) -> Double {
        return doubleFor(keyPath) ?? defaultValue
    }
}

// MARK: Float

extension JSONMapper {
    
    public func floatFor(keyPath: String) -> Float? {
        return rawJSONDictionary.valueForKeyPath(keyPath) as? Float
    }
    
    public func floatValueFor(keyPath: String) -> Float {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! Float
    }
    
    public func floatValueFor(keyPath: String, defaultValue: Float) -> Float {
        return floatFor(keyPath) ?? defaultValue
    }
}

// MARK: Array

extension JSONMapper {
    
    public func arrayFor<T>(keyPath: String) -> [T]? {
        return rawJSONDictionary.valueForKeyPath(keyPath) as? [T]
    }
    
    public func arrayValueFor<T>(keyPath: String) -> [T] {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! [T]
    }
    
    public func arrayValueFor<T>(keyPath: String, defaultValue: [T]) -> [T] {
        return arrayFor(keyPath) ?? defaultValue
    }
}

// MARK: Set

extension JSONMapper {
    
    public func setFor<T>(keyPath: String) -> Set<T>? {
        if let array = rawJSONDictionary.valueForKeyPath(keyPath) as? [T] {
            return Set<T>(array)
        }
        
        return nil
    }
    
    public func setValueFor<T>(keyPath: String) -> Set<T> {
        let array: [T] = rawJSONDictionary.valueForKeyPath(keyPath) as! [T]
        
        return Set<T>(array)
    }
    
    public func setValueFor<T>(keyPath: String, defaultValue: Set<T>) -> Set<T> {
        return setFor(keyPath) ?? defaultValue
    }
}

// MARK: Dictionary

extension JSONMapper {
    
    public func dictionaryFor(keyPath: String) -> JSONDict? {
        return rawJSONDictionary.valueForKeyPath(keyPath) as? JSONDict
    }
    
    public func dictionaryValueFor(keyPath: String) -> JSONDict {
        return rawJSONDictionary.valueForKeyPath(keyPath) as! JSONDict
    }
    
    public func dictionaryValueFor(keyPath: String, defaultValue: JSONDict) -> JSONDict {
        return dictionaryFor(keyPath) ?? defaultValue
    }
}

// MARK: NSDate

extension JSONMapper {
    
    public typealias DateTransformerFromInt = (value: Int) -> NSDate?
    public typealias DateTransformerFromString = (value: String) -> NSDate?
    
    public func dateFromIntFor(keyPath: String, transform: DateTransformerFromInt) -> NSDate? {
        if let value = intFor(keyPath) {
            return transform(value: value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(keyPath: String, transform: DateTransformerFromString) -> NSDate? {
        if let value = stringFor(keyPath) {
            return transform(value: value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(keyPath: String, withFormatterKey formatterKey: String) -> NSDate? {
        if let value = stringFor(keyPath), let formatter = JSONDateFormatter.dateFormatterWith(formatterKey) {
            return formatter.dateFromString(value)
        }
        
        return nil
    }
}

// MARK: URL

extension JSONMapper {
    
    public func urlFrom(keyPath: String) -> NSURL? {
        if let value = stringFor(keyPath) where !value.isEmpty {
            return NSURL(string: value)
        }
        
        return nil
    }
    
    public func urlValueFrom(keyPath: String) -> NSURL {
        let value = stringValueFor(keyPath)
        
        return NSURL(string: value)!
    }
    
    public func urlValueFrom(keyPath: String, defaultValue: NSURL) -> NSURL {
        return urlFrom(keyPath) ?? defaultValue
    }
}

// MARK: Object: JSONMappable

extension JSONMapper {
    
    public func objectFor<T: JSONMappable>(keyPath: String) -> T? {
        if let dict = dictionaryFor(keyPath) {
            let mapper = JSONMapper(dictionary: dict)
            let object = T(mapper: mapper)
            
            return object
        }
        
        return nil
    }
    
    public func objectValueFor<T: JSONMappable>(keyPath: String) -> T {
        let dict = dictionaryValueFor(keyPath)
        
        let mapper = JSONMapper(dictionary: dict)
        let object = T(mapper: mapper)
        
        return object
    }
}

// MARK: Objects Array: JSONMappable

extension JSONMapper {
    
    private func _objectsArrayFrom<T: JSONMappable>(array: JSONArray) -> [T] {
        let results = array.map { (dict: JSONDict) -> T in
            let mapper = JSONMapper(dictionary: dict)
            let object = T(mapper: mapper)
            
            return object
        }
        
        return results
    }
    
    public func objectArrayFor<T: JSONMappable>(keyPath: String) -> [T]? {
        if let arrayValues = rawJSONDictionary.valueForKeyPath(keyPath) as? JSONArray {
            return _objectsArrayFrom(arrayValues)
        }
        
        return nil
    }
    
    public func objectArrayValueFor<T: JSONMappable>(keyPath: String) -> [T] {
        let arrayValues = rawJSONDictionary.valueForKeyPath(keyPath) as! JSONArray
        
        return _objectsArrayFrom(arrayValues)
    }
    
    public func objectArrayValueFor<T: JSONMappable>(keyPath: String, defaultValue: [T]) -> [T] {
        return objectArrayFor(keyPath) ?? defaultValue
    }
}

// MARK: Objects Set: JSONMappable

extension JSONMapper {
    
    public func objectSetFor<T: JSONMappable>(keyPath: String) -> Set<T>? {
        if let values: [T] = objectArrayFor(keyPath) {
            return Set<T>(values)
        }
        
        return nil
    }
    
    public func objectSetValueFor<T: JSONMappable>(keyPath: String) -> Set<T> {
        let values: [T] = objectArrayValueFor(keyPath)
        
        return Set<T>(values)
    }
    
    public func objectSetValueFor<T: JSONMappable>(keyPath: String, defaultValue: Set<T>) -> Set<T> {
        return objectSetFor(keyPath) ?? defaultValue
    }
}

// MARK: Transforms

extension JSONMapper {
    
    public func transform<T, U>(keyPath: String, block: (value: T) -> U?) -> U? {
        if let aValue = rawJSONDictionary.valueForKeyPath(keyPath) as? T {
            return block(value: aValue)
        }
        
        return nil
    }
    
    public func transformValue<T, U>(keyPath: String, defaultValue: U, block: (value: T) -> U) -> U {
        if let aValue = rawJSONDictionary.valueForKeyPath(keyPath) as? T {
            return block(value: aValue)
        }
        
        return defaultValue
    }
}
