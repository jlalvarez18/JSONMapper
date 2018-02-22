//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

public typealias JSONDict = [String: Any]
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
    
    public func value(forKeyPath keyPaths: String...) -> Any? {
        return value(forKeyPaths: keyPaths)
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
    
    mutating public func set(value: Any, forKeyPath keyPath: String) {
        let keys = keyPath.components(separatedBy: ".")
        
        set(value: value, forKeyPaths: keys)
    }
    
    mutating public func set(value: Any, forKeyPath keyPaths: String...) {
        set(value: value, forKeyPaths: keyPaths)
    }
    
    mutating public func set(value: Any, forKeyPaths _keys: [String]) {
        var keys = _keys
        
        guard let first = keys.first as? Key else {
            print("Unable to use string as key on type: \(Key.self)")
            return
        }
        
        keys.remove(at: 0)
        
        if keys.isEmpty, let val = value as? Value {
            self[first] = val
        } else {
            let rejoined = keys.joined(separator: ".")
            
            var subDict: [AnyHashable: Any] = [:]
            
            if let sub = self[first] as? Dictionary {
                subDict = sub
            }
            
            subDict.set(value: value, forKeyPath: rejoined)
            
            if let val = subDict as? Value {
                self[first] = val
            } else {
                print("Unable to set value: \(subDict) to dictionary of type: \(type(of: self))")
            }
        }
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

extension String: RawRepresentable {
    public typealias RawValue = String
    
    public var rawValue: String {
        return self
    }
    
    public init?(rawValue: String) {
        self = rawValue
    }
}

public final class JSONMapper {
    
    public enum Error: Swift.Error {
        case invalidType(expected: Any.Type, actual: Any.Type)
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
    
    public let rawValue: Any?
    
    init(value: Any?, options: JSONAdapter.Options) {
        self.rawValue = value
        self.options = options
    }
    
    public func value<K: RawRepresentable>(for keyPath: K) throws -> Any? where K.RawValue == String {
        let dict: JSONDict = try self.decodeValue()
        
        return dict.value(forKeyPath: keyPath.rawValue)
    }
    
    public func value<K: RawRepresentable>(for keyPaths: [K]) throws -> Any? where K.RawValue == String {
        let dict: JSONDict = try self.decodeValue()
        
        return dict.value(forKeyPaths: keyPaths.map { $0.rawValue })
    }
    
    public func value<K: RawRepresentable>(for keyPaths: K...) throws -> Any? where K.RawValue == String {
        return try self.value(for: keyPaths)
    }
    
    public func contains(keyPath: String) throws -> Bool {
        return try self.value(for: keyPath) != nil
    }
    
    public func contains(keyPath: String...) throws -> Bool {
        return try self.value(for: keyPath) != nil
    }
}

private extension JSONMapper {
    
    func throwKeyPathMissingError<K: RawRepresentable>(_ keys: [K]) -> Error where K.RawValue == String {
        return Error.keyPathMissing(keys.map { $0.rawValue }.joined(separator: "."))
    }
    
    func throwDataCorruptedError<K: RawRepresentable>(_ keys: [K]) -> Error where K.RawValue == String {
        return Error.dataCorrupted(keys.map { $0.rawValue }.joined(separator: "."))
    }
}

// MARK: - Raw Values -

extension JSONMapper {
    
    public func decodeValue<T: JSONType>() throws -> T {
        guard let newValue = self.rawValue as? T else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return T.defaultValue()
            case .throw:
                throw Error.invalidType(expected: T.self, actual: type(of: self.rawValue))
            }
        }
        
        return newValue
    }
    
    public func decodeValue() throws -> JSONDict {
        guard let dict = self.rawValue as? JSONDict else {
            throw Error.invalidType(expected: JSONDict.self, actual: type(of: self.rawValue))
        }
        
        return dict
    }
    
    public func decodeValue() throws -> JSONArray {
        guard let array = self.rawValue as? JSONArray else {
            throw Error.invalidType(expected: JSONArray.self, actual: type(of: self.rawValue))
        }
        
        return array
    }
    
    public func decode<T: JSONType>() -> T? {
        return try? self.decodeValue()
    }
    
    public func decode() -> JSONDict? {
        return try? self.decodeValue()
    }
    
    public func decode() -> JSONArray? {
        return try? self.decodeValue()
    }
}

// MARK: - JSON Types -

extension JSONMapper {
    
    public func decodeValue<T: JSONType, K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> T where K.RawValue == String {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return T.defaultValue()
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        guard let newValue = value as? T else {
            throw Error.invalidType(expected: T.self, actual: type(of: value))
        }
        
        return newValue
    }
    
    public func decodeValue<T: JSONType, K: RawRepresentable>(forKeyPath keyPath: K...) throws -> T where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decodeValue<T: JSONType, K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> [T] where K.RawValue == String {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return []
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        guard let newValue = value as? [T] else {
            throw Error.invalidType(expected: [T].self, actual: type(of: value))
        }
        
        return newValue
    }
    
    public func decodeValue<T: JSONType, K: RawRepresentable>(forKeyPath keyPath: K...) throws -> [T] where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONType, K: RawRepresentable>(forKeyPath keyPath: K...) -> T? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONType, K: RawRepresentable>(forKeyPath keyPath: K...) -> [T]? where K.RawValue == String {
        return try? self.decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - JSON -

extension JSONMapper {
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> JSONDict where K.RawValue == String {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONDict()
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        guard let dict = value as? JSONDict else {
            throw Error.invalidType(expected: JSONDict.self, actual: type(of: value))
        }
        
        return dict
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: K...) throws -> JSONDict where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> JSONArray where K.RawValue == String {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONArray()
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        guard let array = value as? JSONArray else {
            throw Error.invalidType(expected: JSONArray.self, actual: type(of: value))
        }
        
        return array
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: K...) throws -> JSONArray where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<K: RawRepresentable>(forKeyPath keyPath: K...) -> JSONDict? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<K: RawRepresentable>(forKeyPath keyPath: K...) -> JSONArray? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - JSONMappable -

extension JSONMapper {
    
    public func decodeValue<T: JSONMappable, K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> T where K.RawValue == String {
        let mapValue: (Any?) throws -> T = {
            let mapper = JSONMapper(value: $0, options: self.options)
            return try T(mapper: mapper)
        }
        
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return try mapValue(nil)
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        return try mapValue(value)
    }
    
    public func decodeValue<T: JSONMappable, K: RawRepresentable>(forKeyPath keyPath: K...) throws -> T where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decodeValue<T: JSONMappable, K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> [T] where K.RawValue == String {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return []
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        guard let array = value as? [Any] else {
            throw Error.invalidType(expected: [Any].self, actual: type(of: value))
        }
        
        let results = try array.map { (value) -> T in
            let mapper = JSONMapper(value: value, options: self.options)
            return try T(mapper: mapper)
        }
        
        return results
    }
    
    public func decodeValue<T: JSONMappable, K: RawRepresentable>(forKeyPath keyPath: K...) throws -> [T] where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONMappable, K: RawRepresentable>(forKeyPath keyPath: K...) -> T? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONMappable, K: RawRepresentable>(forKeyPath keyPath: K...) -> [T]? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - Bool -

extension JSONMapper {
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> Bool where K.RawValue == String {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return false
            case .throw:
                throw self.throwKeyPathMissingError(keyPath)
            }
        }
        
        let boolValue: Bool?
        
        if let _boolValue = value as? Bool {
            boolValue = _boolValue
        } else if let stringValue = value as? String {
            switch stringValue.lowercased() {
            case "true", "yes", "1":
                boolValue = true
                
            case "false", "no", "0":
                boolValue = false
                
            default:
                boolValue = nil
            }
        } else {
            boolValue = nil
        }
        
        guard let finalValue = boolValue else {
            throw Error.invalidType(expected: Bool.self, actual: type(of: value))
        }
        
        return finalValue
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: K...) throws -> Bool where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<K: RawRepresentable>(forKeyPath keyPath: K...) -> Bool? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - Date -

extension JSONMapper {

    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> Date where K.RawValue == String {
        switch self.dateDecodingStrategy {
        case .formatted(let formatter):
            let value: String = try self.decodeValue(forKeyPath: keyPath)
            
            guard let date = formatter.date(from: value) else {
                throw self.throwDataCorruptedError(keyPath)
            }
            
            return date
        case .secondsSince1970:
            let value: Double = try self.decodeValue(forKeyPath: keyPath)
            
            return Date(timeIntervalSince1970: value)
            
        case .millisecondsSince1970:
            let value: Double = try self.decodeValue(forKeyPath: keyPath)
            
            return Date(timeIntervalSince1970: value/1000.0)
            
        case .iso8601:
            let value: String = try self.decodeValue(forKeyPath: keyPath)
            
            guard let date = iso8601.date(from: value) else {
                throw self.throwDataCorruptedError(keyPath)
            }
            
            return date
            
        case .custom(let block):
            guard let value = try self.value(for: keyPath) else {
                throw self.throwDataCorruptedError(keyPath)
            }
            
            return try block(value)
        }
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: K...) throws -> Date where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<K: RawRepresentable>(forKeyPath keyPath: K...) -> Date? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - Data -

extension JSONMapper {
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> Data where K.RawValue == String {
        switch self.dataDecodingStrategy {
        case .base64:
            let value: String = try self.decodeValue(forKeyPath: keyPath)
            
            guard let data = Data(base64Encoded: value) else {
                throw self.throwDataCorruptedError(keyPath)
            }
            
            return data
            
        case .custom(let block):
            guard let value = try self.value(for: keyPath) else {
                throw self.throwKeyPathMissingError(keyPath)
            }
            
            return try block(value)
        }
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: K...) throws -> Data where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<K: RawRepresentable>(forKeyPath keyPath: K...) -> Data? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - URL -

extension JSONMapper {
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: [K]) throws -> URL where K.RawValue == String {
        let urlString: String = try self.decodeValue(forKeyPath: keyPath)
        
        guard let url = URL(string: urlString) else {
            throw self.throwDataCorruptedError(keyPath)
        }
        
        return url
    }
    
    public func decodeValue<K: RawRepresentable>(forKeyPath keyPath: K...) throws -> URL where K.RawValue == String {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<K: RawRepresentable>(forKeyPath keyPath: K...) -> URL? where K.RawValue == String {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - Transforms -

extension JSONMapper {
    
    public func transform<T, U, K: RawRepresentable>(keyPath: K..., block: (_ value: T) -> U?) throws -> U? where K.RawValue == String {
        if let aValue = try self.value(for: keyPath) as? T {
            return block(aValue)
        }
        
        return nil
    }
    
    public func transformValue<T, U, K: RawRepresentable>(keyPath: K..., defaultValue: U, block: (_ value: T) -> U) throws -> U where K.RawValue == String {
        if let aValue = try self.value(for: keyPath) as? T {
            return block(aValue)
        }
        
        return defaultValue
    }
}

// MARK: - Mapping -

extension JSONMapper {
    
    public func mapArrayFor<T, U, K: RawRepresentable>(keyPath: [K], block: (_ value: T) -> U) throws -> [U]? where K.RawValue == String {
        return try mapArrayFor(keyPath: keyPath, block: block)
    }
    
    public func mapArrayFor<T, U, K: RawRepresentable>(keyPath: K..., block: (_ value: T) -> U) throws -> [U]? where K.RawValue == String {
        if let array = try self.value(for: keyPath) as? [T] {
            let values = array.map(block)
            
            return values
        }
        
        return nil
    }
    
    public func mapArrayValueFor<T, U, K: RawRepresentable>(keyPath: K..., block: (_ value: T) -> U) throws -> [U] where K.RawValue == String {
        return try mapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
    
    public func flatMapArrayFor<T, U, K: RawRepresentable>(keyPath: [K], block: (_ value: T) -> U?) -> [U]? where K.RawValue == String {
        return flatMapArrayFor(keyPath: keyPath, block: block)
    }
    
    public func flatMapArrayFor<T, U, K: RawRepresentable>(keyPath: K..., block: (_ value: T) -> U?) throws -> [U]? where K.RawValue == String {
        if let array = try self.value(for: keyPath) as? [T] {
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
    
    public func flatMapArrayValueFor<T, U, K: RawRepresentable>(keyPath: K..., block: (_ value: T) -> U?) -> [U] where K.RawValue == String {
        return flatMapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
}
