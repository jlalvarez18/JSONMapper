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

public final class JSONMapper {
    
    public enum Error: Swift.Error {
        case invalidType(key: [JSONKey], expected: Any.Type, actual: Any.Type, debugDescription: String)
        case keyPathMissing(key: [JSONKey], debugDescription: String)
        case dataCorrupted(key: [JSONKey], actual: Any?, debugDescription: String)
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
    
    var keyDecodingStrategy: JSONAdapter.KeyDecodingStrategy {
        return options.keyDecodingStrategy
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
        
       return dict.value(forKeyPath: keyPath.map { self.keyDecodingStrategy.convert($0.stringValue()) })
    }
    
    public func value(for keyPath: JSONKey...) throws -> Any? {
        return try self.value(for: keyPath)
    }
    
    public func contains(keyPath: String...) throws -> Bool {
        return try self.value(for: keyPath) != nil
    }
}

extension JSONMapper {
    
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
    
    public func decodeValue() throws -> [Any] {
        guard let value = self.rawValue as? [Any] else {
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

// MARK: - Swift Decodable -

extension JSONMapper {
    
    public func decodeValue<T: Decodable>(forKeyPath keyPath: [JSONKey], decoder: JSONDecoder) throws -> T {
        let value: JSONDict = try self.decodeValue(forKeyPath: keyPath)
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decodeValue<T: Decodable>(forKeyPath keyPath: [JSONKey], decoder: JSONDecoder) throws -> [T] {
        let value: JSONArray = try self.decodeValue(forKeyPath: keyPath)
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode([T].self, from: data)
    }
    
    public func decode<T: Decodable>(forKeyPath keyPath: [JSONKey], decoder: JSONDecoder) -> T? {
        return try? decodeValue(forKeyPath: keyPath, decoder: decoder)
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

    public func decode<T: JSONType>(forKeyPath keyPath: JSONKey...) -> T? {
        return try? decodeValue(forKeyPath: keyPath)
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
    
    public func decode<T: JSONMappable>(forKeyPath keyPath: [JSONKey]) -> T? {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    public func decode<T: JSONMappable>(forKeyPath keyPath: JSONKey...) -> T? {
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
    
    public func compactMapFor<T, U>(keyPath: [JSONKey], block: (_ value: T) throws -> U?) throws -> [U] {
        if let array = try self.value(for: keyPath) as? [T] {
            let newArray = try array.compactMap(block)
            
            return newArray
        }
        
        return []
    }
    
    public func compactMapArrayFor<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U?) -> [U]? {
        return try? compactMapFor(keyPath: keyPath, block: block)
    }
    
    public func compactMapArrayValueFor<T, U>(keyPath: JSONKey..., block: (_ value: T) -> U?) throws -> [U] {
        let values = try compactMapFor(keyPath: keyPath, block: block)
        
        return values
    }
}
