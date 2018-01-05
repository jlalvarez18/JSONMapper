//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

public typealias JSONDict = [String: Any] //NSDictionary
public typealias JSONArray = [JSONDict]

private let iso8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()

extension Dictionary {
    
    public func value(forKeyPath keyPath: String) -> Any? {
        let keys = keyPath.components(separatedBy: ".")
        
        return value(forKeyPaths: keys)
    }
    
    public func value(forKeyPaths keys: [String]) -> Any? {
        var newKeys = keys
        
        guard let first = newKeys.first as? Key else {
            print("Unable to use string as key on type: \(Key.self)")
            return nil
        }
        
        guard let value = self[first] else {
            return nil
        }
        
        newKeys.remove(at: 0)
        
        if !newKeys.isEmpty, let subDict = value as? [String: Any] {
            let rejoined = newKeys.joined(separator: ".")
            
            return subDict.value(forKeyPath: rejoined)
        }
        
        return value
    }
}

public protocol JSONMappable {
    // This should throw if there are any invalid keys, value, etc
    init(mapper: JSONMapper) throws
}

public protocol JSONType {
    static func defaultValue() -> Self
}

extension String: JSONType {
    static public func defaultValue() -> String {
        return ""
    }
}
extension Int: JSONType {
    static public func defaultValue() -> Int {
        return 0
    }
}
extension Int8: JSONType {
    static public func defaultValue() -> Int8 {
        return 0
    }
}
extension Int16: JSONType {
    static public func defaultValue() -> Int16 {
        return 0
    }
}
extension Int32: JSONType {
    static public func defaultValue() -> Int32 {
        return 0
    }
}
extension Int64: JSONType {
    static public func defaultValue() -> Int64 {
        return 0
    }
}
extension UInt: JSONType {
    static public func defaultValue() -> UInt {
        return 0
    }
}
extension UInt8: JSONType {
    static public func defaultValue() -> UInt8 {
        return 0
    }
}
extension UInt16: JSONType {
    static public func defaultValue() -> UInt16 {
        return 0
    }
}
extension UInt32: JSONType {
    static public func defaultValue() -> UInt32 {
        return 0
    }
}
extension UInt64: JSONType {
    static public func defaultValue() -> UInt64 {
        return 0
    }
}
extension Double: JSONType {
    static public func defaultValue() -> Double {
        return 0.0
    }
}
extension Float: JSONType {
    static public func defaultValue() -> Float {
        return 0.0
    }
}

public final class JSONMapper {
    
    enum Error: Swift.Error {
        case invalidType(String)
        case keyPathMissing(String)
        case dataCorrupted(String)
    }
    
    let options: JSONAdapter.Options
    
    var dateDecodingStrategy: JSONAdapter.DateDecodingStrategy {
        return options.dateDecodingStrategy
    }
    
    var dataDecodingStrategy: JSONAdapter.DataDecodingStrategy {
        return options.dataDecodingStrategy
    }
    
    var valueDecodingStrategy: JSONAdapter.ValueDecodingStrategy {
        return options.valueDecodingStrategy
    }
    
    public let rawJSON: JSONDict
    
    init(dictionary: JSONDict, options: JSONAdapter.Options) {
        self.rawJSON = dictionary
        self.options = options
    }
    
    public subscript(keyPath: String) -> Any? {
        return rawJSON.value(forKeyPath: keyPath)
    }
    
    public subscript(keyPaths: [String]) -> Any? {
        return rawJSON.value(forKeyPaths: keyPaths)
    }
}

// MARK: - JSON Types -

extension JSONMapper {
    
    public func decode<T: JSONType>(forKeyPath keyPath: String) -> T? {
        guard let value = self[keyPath] else {
            return nil
        }
        
        return value as? T
    }
    
    public func decodeValue<T: JSONType>(forKeyPath keyPath: String) throws -> T {
        guard let value = self[keyPath] else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return T.defaultValue()
            case .throw:
                throw Error.keyPathMissing(keyPath)
            }
        }
        
        guard let newValue = value as? T else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return T.defaultValue()
            case .throw:
                throw Error.invalidType(String(describing: T.self))
            }
        }
        
        return newValue
    }
    
    public func decode<T: JSONType>(forKeyPath keyPath: String) -> [T]? {
        guard let value = self[keyPath] else {
            return nil
        }
        
        guard let newValue = value as? [T] else {
            return nil
        }
        
        return newValue
    }
    
    public func decodeValue<T: JSONType>(forKeyPath keyPath: String) throws -> [T] {
        guard let value = self[keyPath] else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return []
            case .throw:
                throw Error.keyPathMissing(keyPath)
            }
        }
        
        guard let newValue = value as? [T] else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return []
            case .throw:
                throw Error.invalidType(String(describing: T.self))
            }
        }
        
        return newValue
    }
}

// MARK: - JSON -

extension JSONMapper {
    
    public func decodeValue(forKeyPath keyPath: String) throws -> JSONDict {
        guard let value = self[keyPath] else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONDict()
            case .throw:
                throw Error.keyPathMissing(keyPath)
            }
        }
        
        guard let dict = value as? JSONDict else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONDict()
            case .throw:
                throw Error.invalidType(String(describing: JSONDict.self))
            }
        }
        
        return dict
    }
    
    public func decodeValue(forKeyPath keyPath: String) throws -> JSONArray {
        guard let value = self[keyPath] else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONArray()
            case .throw:
                throw Error.keyPathMissing(keyPath)
            }
        }
        
        guard let array = value as? JSONArray else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONArray()
            case .throw:
                throw Error.invalidType(String(describing: JSONArray.self))
            }
        }
        
        return array
    }
}

// MARK: - JSONMappable -

extension JSONMapper {
    
    public func decodeValue<T: JSONMappable>(forKeyPath keyPath: String) throws -> T {
        guard let value = self[keyPath] else {
            throw Error.keyPathMissing(keyPath)
        }
        
        guard let dict = value as? JSONDict else {
            throw Error.invalidType("Invalid JSON Type")
        }
        
        let mapper = JSONMapper(dictionary: dict, options: self.options)
        
        return try T(mapper: mapper)
    }
    
    public func decode<T: JSONMappable>(forKeyPath keyPath: String) throws -> T? {
        guard let value = self[keyPath] else {
            return nil
        }
        
        guard let dict = value as? JSONDict else {
            return nil
        }
        
        let mapper = JSONMapper(dictionary: dict, options: self.options)
        
        return try T(mapper: mapper)
    }
    
    public func decodeValue<T: JSONMappable>(forKeyPath keyPath: String) throws -> [T] {
        guard let value = self[keyPath] else {
            throw Error.keyPathMissing(keyPath)
        }
        
        guard let array = value as? JSONArray else {
            throw Error.invalidType("Invalid JSON Type")
        }
        
        let results = try array.map { (dict) -> T in
            let mapper = JSONMapper(dictionary: dict, options: self.options)
            return try T(mapper: mapper)
        }
        
        return results
    }
    
    public func decode<T: JSONMappable>(forKeyPath keyPath: String) throws -> [T]? {
        guard let value = self[keyPath] else {
            return nil
        }
        
        guard let array = value as? JSONArray else {
            return nil
        }
        
        let results = try array.map { (dict) -> T in
            let mapper = JSONMapper(dictionary: dict, options: self.options)
            return try T(mapper: mapper)
        }
        
        return results
    }
}

// MARK: - Bool -

extension JSONMapper {
    
    public func decode(forKeyPath keyPath: String) -> Bool? {
        if let value = rawJSON.value(forKeyPath: keyPath) as? Bool {
            return value
        }
        
        if let value = rawJSON.value(forKeyPath: keyPath) as? String {
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
    
    public func decodeValue(forKeyPath keyPath: String) throws -> Bool {
        guard rawJSON.value(forKeyPath: keyPath) != nil else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return false
            case .throw:
                throw Error.keyPathMissing(keyPath)
            }
        }
        
        guard let value: Bool = decode(forKeyPath: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return false
            case .throw:
                throw Error.invalidType(String(describing: Bool.self))
            }
        }
        
        return value
    }
}

// MARK: - Date -

extension JSONMapper {
    
    public func decode(forKeyPath keyPath: String) -> Date? {
        do {
            return try decodeValue(forKeyPath: keyPath)
        } catch {
            return nil
        }
    }
    
    public func decodeValue(forKeyPath keyPath: String) throws -> Date {
        switch self.dateDecodingStrategy {
        case .formatted(let formatter):
            guard let value: String = self.decode(forKeyPath: keyPath) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            guard let date = formatter.date(from: value) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return date
        case .secondsSince1970:
            guard let value: Double = self.decode(forKeyPath: keyPath) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return Date(timeIntervalSince1970: value)
            
        case .millisecondsSince1970:
            guard let value: Double = self.decode(forKeyPath: keyPath) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return Date(timeIntervalSince1970: value/1000.0)
            
        case .iso8601:
            guard let value: String = self.decode(forKeyPath: keyPath) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            guard let date = iso8601.date(from: value) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return date
            
        case .custom(let block):
            guard let value = self[keyPath] else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return try block(value)
        }
    }
}

// MARK: - Data -

extension JSONMapper {
    
    public func decode(forKeyPath keyPath: String) -> Data? {
        do {
            return try decodeValue(forKeyPath: keyPath)
        } catch {
            return nil
        }
    }
    
    public func decodeValue(forKeyPath keyPath: String) throws -> Data {
        switch self.dataDecodingStrategy {
        case .base64:
            guard let value: String = self.decode(forKeyPath: keyPath) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            guard let data = Data(base64Encoded: value) else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return data
            
        case .custom(let block):
            guard let value = self[keyPath] else {
                throw Error.dataCorrupted(keyPath)
            }
            
            return try block(value)
        }
    }
}

// MARK: - URL -

extension JSONMapper {
    
    public func decode(forKeyPath keyPath: String) -> URL? {
        if let value: String = decode(forKeyPath: keyPath), !value.isEmpty {
            return URL(string: value)
        }
        
        return nil
    }
    
    public func decodeValue(forKeyPath keyPath: String) throws -> URL {
        guard let url: URL = decode(forKeyPath: keyPath) else {
            throw Error.dataCorrupted(keyPath)
        }
        
        return url
    }
}

// MARK: - Transforms -

extension JSONMapper {
    
    public func transform<T, U>(keyPath: String, block: (_ value: T) -> U?) -> U? {
        if let aValue = rawJSON.value(forKeyPath: keyPath) as? T {
            return block(aValue)
        }
        
        return nil
    }
    
    public func transformValue<T, U>(keyPath: String, defaultValue: U, block: (_ value: T) -> U) -> U {
        if let aValue = rawJSON.value(forKeyPath: keyPath) as? T {
            return block(aValue)
        }
        
        return defaultValue
    }
}

// MARK: - Mapping -

extension JSONMapper {
    
    public func mapArrayFor<T, U>(keyPath: String, block: (_ value: T) -> U) -> [U]? {
        if let array = rawJSON.value(forKeyPath: keyPath) as? [T] {
            let values = array.map(block)
            
            return values
        }
        
        return nil
    }
    
    public func mapArrayValueFor<T, U>(keyPath: String, block: (_ value: T) -> U) -> [U] {
        return mapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
    
    public func flatMapArrayFor<T, U>(keyPath: String, block: (_ value: T) -> U?) -> [U]? {
        if let array = rawJSON.value(forKeyPath: keyPath) as? [T] {
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
