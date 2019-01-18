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

// MARK: - Keyed Mappers -

extension Mapper {
    
    public func keyedMapperValue() throws -> KeyedMapper {
        guard let value = self.rawValue else {
            throw Error.keyPathMissing(key: "", debugDescription: "Top value is nil")
        }
        
        let actualType = Swift.type(of: value)
        
        guard let dict = self.rawValue as? [String: Any] else {
            throw Mapper.Error.invalidType(key: "",
                                           expected: [String: Any].self,
                                           actual: actualType,
                                           debugDescription: "Expected \([String: Any].self) value but found \(actualType) instead.")
        }
        
        let newMapper = KeyedMapper(mapper: self, wrapping: dict)
        
        return newMapper
    }
    
    public func keyedMapper() throws -> KeyedMapper? {
        return try? keyedMapperValue()
    }
}

// MARK: - Unkeyed Mappers -

extension Mapper {
    
    public func unkeyedMapperValue() throws -> UnkeyedMapper {
        guard let value = self.rawValue else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(keyPath)")
        }
        
        guard let array = value as? [Any] else {
            throw Mapper.Error.invalidType(key: keyPath,
                                           expected: [Any].self,
                                           actual: type(of: value),
                                           debugDescription: "Expected \([Any].self) value but found \(type(of: value)) instead.")
        }
        
        let newMapper = UnkeyedMapper(mapper: self, wrapping: array)
        
        return newMapper
    }
    
    public func unkeyedMapper() throws -> UnkeyedMapper? {
        return try? unkeyedMapperValue()
    }
}

// MARK: - Single Mapper -

extension Mapper {
    
    public func singleMapperValue() throws -> SingleValueMapper {
        guard let value = self.rawValue else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(self.keyPath)")
        }
        
        let newMapper = SingleValueMapper(mapper: self, wrapping: value)
        
        return newMapper
    }
}

// MARK: - Transforms -

//extension Mapper {
//
//    public func transformValue<T, U>(keyPath: Key, block: (_ value: T) -> U) throws -> U {
//        let value = self.value(for: keyPath)
//
//        guard let newValue = value as? T else {
//            throw invalidTypeError(keyPath, expected: T.self, value: type(of: value))
//        }
//
//        return block(newValue)
//    }
//
//    public func transform<T, U>(keyPath: Key, block: (_ value: T) -> U) -> U? {
//        return try? transformValue(keyPath: keyPath, block: block)
//    }
//}
