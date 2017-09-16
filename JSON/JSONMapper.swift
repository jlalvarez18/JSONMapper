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
    private static var formatters: [String: DateFormatter] = [:]
    
    public static func registerDateFormatter(formatter: DateFormatter, withKey key: String) {
        formatters[key] = formatter
    }
    
    public static func dateFormatterWith(key: String) -> DateFormatter? {
        return formatters[key]
    }
}

public final class JSONAdapter <N: JSONMappable> {
    
    private init() {}
    
    public class func objectFromJSONDictionary(dict: JSONDict) -> N {
        let mapper = JSONMapper(dictionary: dict)
        let object = N(mapper: mapper)
        
        return object
    }
    
    public class func objectsFromJSONArray(array: JSONArray) -> [N] {
        let results = array.map({ (json: JSONDict) -> N in
            return self.objectFromJSONDictionary(dict: json)
        })
        
        return results
    }
    
    public class func objectsFromJSONFile(url: URL) throws -> [N]? {
        let data = try Data(contentsOf: url)
        
        return try objectsFromJSONData(data: data)
    }
    
    public class func objectsFromJSONData(data: Data) throws -> [N]? {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        if let dict = json as? JSONDict {
            return [objectFromJSONDictionary(dict: dict)]
        }
        
        if let array = json as? JSONArray {
            return objectsFromJSONArray(array: array)
        }
        
        return nil
    }
    
    public class func objectsFrom(array: [AnyObject]) -> [N]? {
        if let array = array as? JSONArray {
            return objectsFromJSONArray(array: array)
        }
        
        return nil
    }
    
    public class func objectsValueFrom(array: [AnyObject]) -> [N] {
        if let array = objectsFrom(array: array) {
            return array
        }
        
        return []
    }
    
    public class func objectFrom(object: AnyObject) -> N? {
        if let dict = object as? JSONDict {
            return objectFromJSONDictionary(dict: dict)
        }
        
        return nil
    }
}

public final class JSONMapper {
    
    public let rawJSONDictionary: JSONDict
    
    public init(dictionary: JSONDict) {
        rawJSONDictionary = dictionary
    }
    
    public subscript(keyPath: String) -> Any? {
        return rawJSONDictionary.value(forKeyPath: keyPath)
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
        
        self.init(dictionary: dictionary as JSONDict)
    }
}

// MARK: String

extension JSONMapper {
    
    public func stringFor(keyPath: String) -> String? {
        return rawJSONDictionary.value(forKeyPath: keyPath) as? String
    }
    
    public func stringValueFor(keyPath: String) -> String {
        return stringFor(keyPath: keyPath) ?? ""
    }
    
    public func stringValueFor(keyPath: String, defaultValue: String) -> String {
        return stringFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Int

extension JSONMapper {
    
    public func intFor(keyPath: String) -> Int? {
        return rawJSONDictionary.value(forKeyPath: keyPath) as? Int
    }
    
    public func intValueFor(keyPath: String) -> Int {
        return intFor(keyPath: keyPath) ?? 0
    }
    
    public func intValueFor(keyPath: String, defaultValue: Int) -> Int {
        return intFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Bool

extension JSONMapper {
    
    public func boolFor(keyPath: String) -> Bool? {
        if let value = rawJSONDictionary.value(forKeyPath: keyPath) as? Bool {
            return value
        }
        
        if let value = rawJSONDictionary.value(forKeyPath: keyPath) as? String {
            switch value.lowercased() {
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
        return boolFor(keyPath: keyPath) ?? false
    }
    
    public func boolValueFor(keyPath: String, defaultValue: Bool) -> Bool {
        return boolFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Double

extension JSONMapper {
    
    public func doubleFor(keyPath: String) -> Double? {
        return rawJSONDictionary.value(forKeyPath: keyPath) as? Double
    }
    
    public func doubleValueFor(keyPath: String) -> Double {
        return doubleFor(keyPath: keyPath) ?? 0.0
    }
    
    public func doubleValueFor(keyPath: String, defaultValue: Double) -> Double {
        return doubleFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Float

extension JSONMapper {
    
    public func floatFor(keyPath: String) -> Float? {
        return rawJSONDictionary.value(forKeyPath: keyPath) as? Float
    }
    
    public func floatValueFor(keyPath: String) -> Float {
        return floatFor(keyPath: keyPath) ?? 0.0
    }
    
    public func floatValueFor(keyPath: String, defaultValue: Float) -> Float {
        return floatFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Array

extension JSONMapper {
    
    public func arrayFor<T>(keyPath: String) -> [T]? {
        return rawJSONDictionary.value(forKeyPath: keyPath) as? [T]
    }
    
    public func arrayValueFor<T>(keyPath: String) -> [T] {
        return arrayFor(keyPath: keyPath) ?? [T]()
    }
    
    public func arrayValueFor<T>(keyPath: String, defaultValue: [T]) -> [T] {
        return arrayFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Set

extension JSONMapper {
    
    public func setFor<T>(keyPath: String) -> Set<T>? {
        if let array = rawJSONDictionary.value(forKeyPath: keyPath) as? [T] {
            return Set<T>(array)
        }
        
        return nil
    }
    
    public func setValueFor<T>(keyPath: String) -> Set<T> {
        return setFor(keyPath: keyPath) ?? Set<T>()
    }
    
    public func setValueFor<T>(keyPath: String, defaultValue: Set<T>) -> Set<T> {
        return setFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Dictionary

extension JSONMapper {
    
    public func dictionaryFor(keyPath: String) -> JSONDict? {
        return rawJSONDictionary.value(forKeyPath: keyPath) as? JSONDict
    }
    
    public func dictionaryValueFor(keyPath: String) -> JSONDict {
        return dictionaryFor(keyPath: keyPath) ?? JSONDict()
    }
    
    public func dictionaryValueFor(keyPath: String, defaultValue: JSONDict) -> JSONDict {
        return dictionaryFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: NSDate

extension JSONMapper {
    
    public typealias DateTransformerFromInt = (_ value: Int) -> Date?
    public typealias DateTransformerFromString = (_ value: String) -> Date?
    
    public func dateFromIntFor(keyPath: String, transform: DateTransformerFromInt) -> Date? {
        if let value = intFor(keyPath: keyPath) {
            return transform(value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(keyPath: String, transform: DateTransformerFromString) -> Date? {
        if let value = stringFor(keyPath: keyPath) {
            return transform(value)
        }
        
        return nil
    }
    
    public func dateFromStringFor(keyPath: String, withFormatterKey formatterKey: String) -> Date? {
        if let value = stringFor(keyPath: keyPath), let formatter = JSONDateFormatter.dateFormatterWith(key: formatterKey) {
            return formatter.date(from: value)
        }
        
        return nil
    }
}

// MARK: URL

extension JSONMapper {
    
    public func urlFrom(keyPath: String) -> URL? {
        if let value = stringFor(keyPath: keyPath), !value.isEmpty {
            return URL(string: value)
        }
        
        return nil
    }
    
    public func urlValueFrom(keyPath: String, defaultValue: URL) -> URL {
        return urlFrom(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Object: JSONMappable

extension JSONMapper {
    
    public func objectFor<T: JSONMappable>(keyPath: String) -> T? {
        if let dict = dictionaryFor(keyPath: keyPath) {
            let mapper = JSONMapper(dictionary: dict)
            let object = T(mapper: mapper)
            
            return object
        }
        
        return nil
    }
    
    public func objectValueFor<T: JSONMappable>(keyPath: String) -> T {
        let dict = dictionaryValueFor(keyPath: keyPath)
        
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
        if let arrayValues = rawJSONDictionary.value(forKeyPath: keyPath) as? JSONArray {
            return _objectsArrayFrom(array: arrayValues)
        }
        
        return nil
    }
    
    public func objectArrayValueFor<T: JSONMappable>(keyPath: String) -> [T] {
        let arrayValues = rawJSONDictionary.value(forKeyPath: keyPath) as? JSONArray ?? JSONArray()
        
        return _objectsArrayFrom(array: arrayValues)
    }
    
    public func objectArrayValueFor<T: JSONMappable>(keyPath: String, defaultValue: [T]) -> [T] {
        return objectArrayFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Objects Set: JSONMappable

extension JSONMapper {
    
    public func objectSetFor<T: JSONMappable>(keyPath: String) -> Set<T>? {
        if let values: [T] = objectArrayFor(keyPath: keyPath) {
            return Set<T>(values)
        }
        
        return nil
    }
    
    public func objectSetValueFor<T: JSONMappable>(keyPath: String) -> Set<T> {
        return objectSetFor(keyPath: keyPath) ?? Set<T>()
    }
    
    public func objectSetValueFor<T: JSONMappable>(keyPath: String, defaultValue: Set<T>) -> Set<T> {
        return objectSetFor(keyPath: keyPath) ?? defaultValue
    }
}

// MARK: Transforms

extension JSONMapper {
    
    public func transform<T, U>(keyPath: String, block: (_ value: T) -> U?) -> U? {
        if let aValue = rawJSONDictionary.value(forKeyPath: keyPath) as? T {
            return block(aValue)
        }
        
        return nil
    }
    
    public func transformValue<T, U>(keyPath: String, defaultValue: U, block: (_ value: T) -> U) -> U {
        if let aValue = rawJSONDictionary.value(forKeyPath: keyPath) as? T {
            return block(aValue)
        }
        
        return defaultValue
    }
}

// MARK: Mapping

extension JSONMapper {
    
    public func mapArrayFor<T, U>(keyPath: String, block: (_ value: T) -> U) -> [U]? {
        if let array = rawJSONDictionary.value(forKeyPath: keyPath) as? [T] {
            let values = array.map(block)
            
            return values
        }
        
        return nil
    }
    
    public func mapArrayValueFor<T, U>(keyPath: String, block: (_ value: T) -> U) -> [U] {
        return mapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
    
    public func flatMapArrayFor<T, U>(keyPath: String, block: (_ value: T) -> U?) -> [U]? {
        if let array = rawJSONDictionary.value(forKeyPath: keyPath) as? [T] {
            var newValues = [U]()
            
            for item in array {
                if let value = block(item) {
                    newValues.append(value)
                }
            }
            
            return newValues
        }
        
        return nil
    }
    
    public func flatMapArrayValueFor<T, U>(keyPath: String, block: (_ value: T) -> U?) -> [U] {
        return flatMapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
}
