//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

public final class Mapper {
    
    public enum Error: Swift.Error {
        case invalidType(key: Key, expected: Any.Type, actual: Any.Type, debugDescription: String)
        case keyPathMissing(key: Key, debugDescription: String)
        case dataCorrupted(key: Key, actual: Any?, debugDescription: String)
    }
    
    let options: Adapter.Options
    
    var dateDecodingStrategy: Adapter.DateDecodingStrategy {
        return options.dateDecodingStrategy
    }
    
    var dataDecodingStrategy: Adapter.DataDecodingStrategy {
        return options.dataDecodingStrategy
    }
    
    var keyDecodingStrategy: Adapter.KeyDecodingStrategy {
        return options.keyDecodingStrategy
    }
    
    var nonConformingFloatDecodingStrategy: Adapter.NonConformingFloatDecodingStrategy {
        return options.nonConformingFloatDecodingStrategy
    }
    
    public let rawValue: Any?
    public let keyPath: Key
    
    init(value: Any?, keyPath: Key, options: Adapter.Options) {
        self.rawValue = value
        self.keyPath = keyPath
        self.options = options
    }
    
    func value(for keyPath: Key) -> Any? {
        guard let dict = self.rawValue as? [String: Any] else {
            return nil
        }
        
       return dict.value(forKeyPath: keyPath.keys().map { self.keyDecodingStrategy.convert($0.stringValue()) })
    }
    
    func contains(keyPath: [String]) -> Bool {
        return self.value(for: keyPath) != nil
    }
}

extension Mapper {
    
    public func keyPathMissingError(_ keyPath: Key) -> Error {
        let keys = keyPath.keys()
        
        if keys.isEmpty {
            return Error.keyPathMissing(key: keys, debugDescription: "Top value is nil")
        }
        
        return Error.keyPathMissing(key: keys, debugDescription: "No value associated with keyPath \(keys)")
    }
    
    public func invalidTypeError(_ keys: Key, expected: Any.Type, value: Any?) -> Error {
        if let v = value {
            return Error.invalidType(key: keys, expected: expected, actual: type(of: v), debugDescription: "Expected \(expected) value but found \(type(of: v)) instead.")
        }
        
        return Error.invalidType(key: keys, expected: expected, actual: Any.self, debugDescription: "Expected \(expected) value but found nil instead.")
    }
    
    public func dataCorrupted(_ keys: Key, actual: Any?, debugDescription: String) -> Error {
        return Error.dataCorrupted(key: self.keyPath, actual: actual, debugDescription: debugDescription)
    }
}

// MARK: - JSON Object -

extension Mapper {
    
    public func decodeJSONObjectValue() throws -> Any {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        return value
    }
    
    public func decodeJSONObjectValue(forKeyPath keyPath: Key) throws -> Any {
        guard let value = self.value(for: keyPath) else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        return value
    }
    
    public func decodeJSONObject() -> Any? {
        return try? decodeJSONObjectValue()
    }
    
    public func decodeJSONObject(forKeyPath keyPath: Key) throws -> Any? {
        return try? decodeJSONObjectValue(forKeyPath: keyPath)
    }
}

// MARK: - JSON Object Array -

extension Mapper {
    
    public func decodeJSONArrayValue() throws -> [Any] {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        guard let newValue = value as? [Any] else {
            throw self.invalidTypeError(keyPath, expected: [Any].self, value: value)
        }
        
        return newValue
    }
    
    public func decodeJSONArrayValue(forKeyPath keyPath: Key) throws -> [Any] {
        guard let value = self.value(for: keyPath) else {
            throw self.keyPathMissingError(keyPath)
        }
        
        guard let newValue = value as? [Any] else {
            throw self.invalidTypeError(keyPath, expected: [Any].self, value: value)
        }
        
        return newValue
    }
    
    public func decodeJSONArray() -> [Any]? {
        return try? decodeJSONArrayValue()
    }
    
    public func decodeJSONArray(forKeyPath keyPath: Key) -> [Any]? {
        return try? decodeJSONArrayValue(forKeyPath: keyPath)
    }
}

// MARK: - Mappable -

extension Mapper {
    
    public func decodeValue<T>() throws -> T where T: Mappable {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        let mapper = Mapper(value: value, keyPath: self.keyPath, options: self.options)
        return try T(mapper: mapper)
    }
    
    public func decode<T>() -> T? where T: Mappable {
        return try? self.decodeValue()
    }
    
    public func decodeValue<T>(forKeyPath keyPath: Key) throws -> T where T: Mappable {
        guard let value = self.value(for: keyPath) else {
            throw self.keyPathMissingError(keyPath)
        }
        
        let mapper = Mapper(value: value, keyPath: keyPath, options: self.options)
        return try T(mapper: mapper)
    }
    
    public func decode<T>(forKeyPath keyPath: Key) -> T? where T: Mappable {
        return try? decodeValue(forKeyPath: keyPath)
    }
}

// MARK: - Swift Decodable -

extension Mapper {
    
    public func decodeValue<T>(decoder: JSONDecoder) throws -> T where T: Decodable {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decode<T>(decoder: JSONDecoder) throws -> T? where T: Decodable {
        return try? decodeValue(decoder: decoder)
    }
    
    public func decodeValue<T>(forKeyPath keyPath: Key, decoder: JSONDecoder) throws -> T where T: Decodable {
        guard let value = self.value(for: keyPath) else {
            throw self.keyPathMissingError(keyPath)
        }
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decode<T>(forKeyPath keyPath: Key, decoder: JSONDecoder) -> T? where T: Decodable {
        return try? decodeValue(forKeyPath: keyPath, decoder: decoder)
    }
}

// MARK: - Transforms -

extension Mapper {
    
    public func transformValue<T, U>(keyPath: Key, block: (_ value: T) -> U) throws -> U {
        let value = self.value(for: keyPath)
        
        guard let newValue = value as? T else {
            throw invalidTypeError(keyPath, expected: T.self, value: type(of: value))
        }
        
        return block(newValue)
    }
    
    public func transform<T, U>(keyPath: Key, block: (_ value: T) -> U) -> U? {
        return try? transformValue(keyPath: keyPath, block: block)
    }
}
