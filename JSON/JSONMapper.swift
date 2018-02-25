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

extension Dictionary {
    
    public func value(forKeyPath keyPath: String...) -> Any? {
        return value(forKeyPath: keyPath)
    }
    
    public func value(forKeyPath keys: [String]) -> Any? {
        var newKeys = keys.flatMap { $0.components(separatedBy: ".") }
        
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
    
    mutating public func set(value: Any, forKeyPath keyPath: String...) {
        set(value: value, forKeyPath: keyPath)
    }
    
    mutating public func set(value: Any, forKeyPath keyPath: [String]) {
        var keys = keyPath
        
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

public protocol JSONKey {
    func stringValue() -> String
}

extension String: JSONKey {
    public func stringValue() -> String {
        return self
    }
}

public extension RawRepresentable where RawValue == String {
    func stringValue() -> String {
        return self.rawValue
    }
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

extension Collection where Element == String {
    
    func keyPath() -> String {
        return self.map { $0 }.joined(separator: ".")
    }
}

public final class JSONMapper {
    
    public enum Error: Swift.Error {
        case invalidType(key: [JSONKey], expected: Any.Type, actual: Any.Type, debugDescription: String)
        case keyPathMissing(key: [JSONKey], debugDescription: String)
        case dataCorrupted(key: [JSONKey], debugDescription: String)
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
    public let keyPath: [JSONKey]
    
    init(value: Any?, keyPath: [JSONKey], options: JSONAdapter.Options) {
        self.rawValue = value
        self.keyPath = keyPath
        self.options = options
    }
    
    public func value(for keyPath: [JSONKey]) throws -> Any? {
        let dict: JSONDict = try self.decodeValue()
        
       return dict.value(forKeyPath: keyPath.map { $0.stringValue() })
    }
    
    public func value(for keyPath: JSONKey...) throws -> Any? {
        return try self.value(for: keyPath)
    }
    
    public func contains(keyPath: String...) throws -> Bool {
        return try self.value(for: keyPath) != nil
    }
}

internal extension JSONMapper {
    
    func keyPathMissingError(_ keys: [JSONKey]) -> Error {
        if keys.isEmpty {
            return Error.keyPathMissing(key: keys, debugDescription: "Top value is nil")
        }
        
        return Error.keyPathMissing(key: keys, debugDescription: "No value associated with keyPath \(keys)")
    }
    
    func invalidTypeError(_ keys: [JSONKey], expected: Any.Type, value: Any?) -> Error {
        if let v = value {
            return Error.invalidType(key: keys, expected: expected, actual: type(of: v), debugDescription: "Expected \(expected) value but found \(type(of: v)) instead.")
        }
        
        return Error.invalidType(key: keys, expected: expected, actual: Any.self, debugDescription: "Expected \(expected) value but found nil instead.")
    }
}

// MARK: - Raw Values -

extension JSONMapper {
    
    public func decodeValue<T: JSONMappable>() throws -> T {
        guard let value = self.rawValue else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                let mapper = JSONMapper(value: nil, keyPath: self.keyPath, options: self.options)
                return try T(mapper: mapper)
            case .throw:
                throw self.keyPathMissingError(self.keyPath)
            }
        }
        
        let mapper = JSONMapper(value: value, keyPath: self.keyPath, options: self.options)
        return try T(mapper: mapper)
    }
    
    public func decodeValue<T: JSONType>() throws -> T {
        guard let value = self.rawValue else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return T.defaultValue()
            case .throw:
                throw self.keyPathMissingError(self.keyPath)
            }
        }
        
        guard let newValue = value as? T else {
            throw invalidTypeError(self.keyPath, expected: T.self, value: self.rawValue)
        }
        
        return newValue
    }
    
    public func decodeValue() throws -> JSONDict {
        guard let dict = self.rawValue as? JSONDict else {
            throw invalidTypeError(self.keyPath, expected: JSONDict.self, value: self.rawValue)
        }
        
        return dict
    }
    
    public func decodeValue() throws -> JSONArray {
        guard let array = self.rawValue as? JSONArray else {
            throw invalidTypeError(self.keyPath, expected: JSONArray.self, value: self.rawValue)
        }
        
        return array
    }
    
    public func decodeValue() throws -> Any {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        return value
    }
    
    public func decode<T: JSONMappable>() -> T? {
        return try? self.decodeValue()
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
    
    public func decode() -> Any? {
        return try? self.decodeValue()
    }
}

// MARK: - JSON Types -

extension JSONMapper {
    
    public func decodeValue<T: JSONType>(forKeyPath keyPath: [JSONKey]) throws -> T {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return T.defaultValue()
            case .throw:
                throw self.keyPathMissingError(keyPath)
            }
        }
        
        guard let newValue = value as? T else {
            throw invalidTypeError(self.keyPath, expected: T.self, value: value)
        }
        
        return newValue
    }
    
    public func decodeValue<T: JSONType>(forKeyPath keyPath: JSONKey...) throws -> T {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decodeValue<T: JSONType>(forKeyPath keyPath: [JSONKey]) throws -> [T] {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return []
            case .throw:
                throw self.keyPathMissingError(keyPath)
            }
        }
        
        guard let newValue = value as? [T] else {
            throw invalidTypeError(self.keyPath, expected: [T].self, value: value)
        }
        
        return newValue
    }
    
    public func decodeValue<T: JSONType>(forKeyPath keyPath: JSONKey...) throws -> [T] {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONType>(forKeyPath keyPath: JSONKey...) -> T? {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONType>(forKeyPath keyPath: JSONKey...) -> [T]? {
        return try? self.decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - JSON -

extension JSONMapper {
    
    public func decodeValue(forKeyPath keyPath: [JSONKey]) throws -> JSONDict {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONDict()
            case .throw:
                throw self.keyPathMissingError(keyPath)
            }
        }
        
        guard let dict = value as? JSONDict else {
            throw invalidTypeError(self.keyPath, expected: JSONDict.self, value: value)
        }
        
        return dict
    }
    
    public func decodeValue(forKeyPath keyPath: JSONKey...) throws -> JSONDict {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decodeValue(forKeyPath keyPath: [JSONKey]) throws -> JSONArray {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return JSONArray()
            case .throw:
                throw self.keyPathMissingError(keyPath)
            }
        }
        
        guard let array = value as? JSONArray else {
            throw invalidTypeError(self.keyPath, expected: JSONArray.self, value: value)
        }
        
        return array
    }
    
    public func decodeValue(forKeyPath keyPath: JSONKey...) throws -> JSONArray {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode(forKeyPath keyPath: JSONKey...) -> JSONDict? {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode(forKeyPath keyPath: JSONKey...) -> JSONArray? {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - JSONMappable -

extension JSONMapper {
    
    public func decodeValue<T: JSONMappable>(forKeyPath keyPath: [JSONKey]) throws -> T {
        let mapValue: (Any?) throws -> T = {
            let mapper = JSONMapper(value: $0, keyPath: keyPath, options: self.options)
            return try T(mapper: mapper)
        }
        
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return try mapValue(nil)
            case .throw:
                throw self.keyPathMissingError(keyPath)
            }
        }
        
        return try mapValue(value)
    }
    
    public func decodeValue<T: JSONMappable>(forKeyPath keyPath: JSONKey...) throws -> T {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decodeValue<T: JSONMappable>(forKeyPath keyPath: [JSONKey]) throws -> [T] {
        guard let value = try self.value(for: keyPath) else {
            switch valueDecodingStrategy {
            case .useDefaultValues:
                return []
            case .throw:
                throw self.keyPathMissingError(keyPath)
            }
        }
        
        guard let array = value as? [Any] else {
            throw invalidTypeError(self.keyPath, expected: [Any].self, value: value)
        }
        
        let results = try array.map { (value) -> T in
            let mapper = JSONMapper(value: value, keyPath: keyPath, options: self.options)
            return try T(mapper: mapper)
        }
        
        return results
    }
    
    public func decodeValue<T: JSONMappable>(forKeyPath keyPath: JSONKey...) throws -> [T] {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONMappable>(forKeyPath keyPath: JSONKey...) -> T? {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONMappable>(forKeyPath keyPath: JSONKey...) -> [T]? {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - Transforms -

extension JSONMapper {
    
    public func transform<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U?) throws -> U? {
        if let aValue = try self.value(for: keyPath) as? T {
            return block(aValue)
        }
        
        return nil
    }
    
    public func transformValue<T, U>(keyPath: JSONKey..., defaultValue: U, block: (_ value: T) -> U) throws -> U {
        if let aValue = try self.value(for: keyPath) as? T {
            return block(aValue)
        }
        
        return defaultValue
    }
}

// MARK: - Mapping -

extension JSONMapper {
    
    public func mapArrayFor<T, U>(keyPath: [JSONKey], block: (_ value: T) -> U) throws -> [U]? {
        if let array = try self.value(for: keyPath) as? [T] {
            let values = array.map(block)
            
            return values
        }
        
        return nil
    }
    
    public func mapArrayFor<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U) throws -> [U]? {
        return try mapArrayFor(keyPath: keyPath, block: block)
    }
    
    public func mapArrayValueFor<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U) throws -> [U] {
        return try mapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
    
    public func flatMapArrayFor<T, U>(keyPath: [JSONKey], block: (_ value: T) -> U?) -> [U]? {
        return flatMapArrayFor(keyPath: keyPath, block: block)
    }
    
    public func flatMapArrayFor<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U?) throws -> [U]? {
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
    
    public func flatMapArrayValueFor<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U?) -> [U] {
        return flatMapArrayFor(keyPath: keyPath, block: block) ?? [U]()
    }
}
