//
//  JSON.swift
//  JSON
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

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

extension Collection where Element == String {
    
    func keyPath() -> String {
        return self.map { $0 }.joined(separator: ".")
    }
}

public final class Mapper {
    
    public enum Error: Swift.Error {
        case invalidType(key: [JSONKey], expected: Any.Type, actual: Any.Type, debugDescription: String)
        case keyPathMissing(key: [JSONKey], debugDescription: String)
        case dataCorrupted(key: [JSONKey], actual: Any?, debugDescription: String)
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
    public let keyPath: [JSONKey]
    
    init(value: Any?, keyPath: [JSONKey], options: Adapter.Options) {
        self.rawValue = value
        self.keyPath = keyPath
        self.options = options
    }
    
    public func value(for keyPath: [JSONKey]) throws -> Any? {
        let dict: [String: Any] = try self.decodeValue()
        
       return dict.value(forKeyPath: keyPath.map { self.keyDecodingStrategy.convert($0.stringValue()) })
    }
    
    public func value(for keyPath: JSONKey...) throws -> Any? {
        return try self.value(for: keyPath)
    }
    
    public func contains(keyPath: String...) throws -> Bool {
        return try self.value(for: keyPath) != nil
    }
}

extension Mapper {
    
    public func keyPathMissingError(_ keys: [JSONKey]) -> Error {
        if keys.isEmpty {
            return Error.keyPathMissing(key: keys, debugDescription: "Top value is nil")
        }
        
        return Error.keyPathMissing(key: keys, debugDescription: "No value associated with keyPath \(keys)")
    }
    
    public func invalidTypeError(_ keys: [JSONKey], expected: Any.Type, value: Any?) -> Error {
        if let v = value {
            return Error.invalidType(key: keys, expected: expected, actual: type(of: v), debugDescription: "Expected \(expected) value but found \(type(of: v)) instead.")
        }
        
        return Error.invalidType(key: keys, expected: expected, actual: Any.self, debugDescription: "Expected \(expected) value but found nil instead.")
    }
    
    public func dataCorrupted(_ keys: [JSONKey], actual: Any?, debugDescription: String) -> Error {
        return Error.dataCorrupted(key: self.keyPath, actual: actual, debugDescription: debugDescription)
    }
}

// MARK: - Raw Values -

extension Mapper {
    
    public func decodeValue<T: Mappable>() throws -> T {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        let mapper = Mapper(value: value, keyPath: self.keyPath, options: self.options)
        return try T(mapper: mapper)
    }
    
    public func decode<T: Mappable>() -> T? {
        return try? self.decodeValue()
    }
    
    public func decodeValue() throws -> Any {
        guard let value = self.rawValue else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        return value
    }
    
    public func decode() -> Any? {
        return try? self.decodeValue()
    }
    
    public func decodeValue() throws -> [Any] {
        guard let value = self.rawValue as? [Any] else {
            throw self.keyPathMissingError(self.keyPath)
        }
        
        return value
    }
    
    public func decode() -> [Any]? {
        return try? self.decodeValue()
    }
}

// MARK: - Swift Decodable -

extension Mapper {
    
    public func decodeValue<T: Decodable>(forKeyPath keyPath: [JSONKey], decoder: JSONDecoder) throws -> T {
        let value: [String: Any] = try self.decodeValue(forKeyPath: keyPath)
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decodeValue<T: Decodable>(forKeyPath keyPath: [JSONKey], decoder: JSONDecoder) throws -> [T] {
        let value: [[String: Any]] = try self.decodeValue(forKeyPath: keyPath)
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode([T].self, from: data)
    }
    
    public func decode<T: Decodable>(forKeyPath keyPath: [JSONKey], decoder: JSONDecoder) -> T? {
        return try? decodeValue(forKeyPath: keyPath, decoder: decoder)
    }
}

// MARK: - JSONMappable -

extension Mapper {
    
    public func decodeValue<T: Mappable>(forKeyPath keyPath: [JSONKey]) throws -> T {
        let mapValue: (Any?) throws -> T = {
            let mapper = Mapper(value: $0, keyPath: keyPath, options: self.options)
            return try T(mapper: mapper)
        }
        
        guard let value = try self.value(for: keyPath) else {
            throw self.keyPathMissingError(keyPath)
        }
        
        return try mapValue(value)
    }
    
    public func decodeValue<T: Mappable>(forKeyPath keyPath: JSONKey...) throws -> T {
        return try decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: Mappable>(forKeyPath keyPath: [JSONKey]) -> T? {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: Mappable>(forKeyPath keyPath: JSONKey...) -> T? {
        return decode(forKeyPath: keyPath)
    }
}

// MARK: - Transforms -

extension Mapper {
    
    public func transformValue<T, U>(keyPath: [JSONKey], block: (_ value: T) -> U) throws -> U {
        let value = try self.value(for: keyPath)
        
        guard let newValue = value as? T else {
            throw invalidTypeError(keyPath, expected: T.self, value: type(of: value))
        }
        
        return block(newValue)
    }
    
    public func transformValue<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U) throws -> U {
        return try transformValue(keyPath: keyPath, block: block)
    }
    
    public func transform<T, U>(keyPath: [JSONKey], block: (_ value: T) -> U) -> U? {
        return try? transformValue(keyPath: keyPath, block: block)
    }
    
    public func transform<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U) -> U? {
        return transform(keyPath: keyPath, block: block)
    }
}
