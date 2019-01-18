//
//  KeyedMapper.swift
//  JSON
//
//  Created by Juan Alvarez on 1/17/19.
//  Copyright © 2019 Alvarez Productions. All rights reserved.
//

import Foundation

public struct KeyedMapper {
    public let keyPath: Key
    public let rawValue: [String: Any]
    
    private let mapper: Mapper
    
    init(mapper: Mapper, wrapping container: [String: Any]) {
        self.mapper = mapper
        self.rawValue = container
        self.keyPath = mapper.keyPath
    }
    
    public func contains(_ keyPath: Key) -> Bool {
        return self.rawValue[keyPath.stringValue()] != nil
    }
    
    public var allKeys: [Key] {
        return self.rawValue.keys.map { $0 }
    }
    
    public func value(forKeyPath keyPath: Key) -> Any? {
        let keys = keyPath.keys().map { self.mapper.keyDecodingStrategy.convert($0.stringValue()) }
        
        return self.rawValue.value(forKeyPath: keys)
    }
    
    // MARK: - Mappable Values -
    
    public func decodeValue<T>(forKeyPath keyPath: Key) throws -> T where T: Mappable {
        guard let value = self.value(forKeyPath: keyPath) else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(keyPath)")
        }
        
        let newMapper = Mapper(value: value, keyPath: keyPath, options: self.mapper.options)
        
        return try T(mapper: newMapper)
    }
    
    public func decode<T>(forKeyPath keyPath: Key) -> T? where T: Mappable {
        return try? decodeValue(forKeyPath: keyPath)
    }
    
    // MARK: - Decodable Values -
    
    public func decodeValue<T>(forKeyPath keyPath: Key, decoder: JSONDecoder) throws -> T where T: Decodable {
        guard let value = self.value(forKeyPath: keyPath) else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(keyPath)")
        }
        
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decode<T>(forKeyPath keyPath: Key, decoder: JSONDecoder) -> T? where T: Decodable {
        return try? decodeValue(forKeyPath: keyPath, decoder: decoder)
    }
    
    // MARK: - Keyed Mapper Values -
    
    public func keyedMapperValue(forKeyPath keyPath: Key) throws -> KeyedMapper {
        guard let value = self.value(forKeyPath: keyPath) else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(keyPath)")
        }
        
        guard let dict = value as? [String: Any] else {
            throw Mapper.Error.invalidType(key: keyPath,
                                           expected: [String: Any].self,
                                           actual: type(of: value),
                                           debugDescription: "Expected \([String: Any].self) value but found \(type(of: value)) instead.")
        }
        
        let newMapper = KeyedMapper(mapper: self.mapper, wrapping: dict)
        
        return newMapper
    }
    
    public func keyedMapper(forKeyPath keyPath: Key) throws -> KeyedMapper? {
        return try? keyedMapperValue(forKeyPath: keyPath)
    }
    
    // MARK: - Unkeyed Mapper values -
    
    public func unkeyedMapperValue(forKeyPath keyPath: Key) throws -> UnkeyedMapper {
        guard let value = self.value(forKeyPath: keyPath) else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(keyPath)")
        }
        
        guard let array = value as? [Any] else {
            throw Mapper.Error.invalidType(key: keyPath,
                                           expected: [Any].self,
                                           actual: type(of: value),
                                           debugDescription: "Expected \([Any].self) value but found \(type(of: value)) instead.")
        }
        
        let newMapper = UnkeyedMapper(mapper: self.mapper, wrapping: array)
        
        return newMapper
    }
    
    public func unkeyedMapper(forKeyPath keyPath: Key) throws -> UnkeyedMapper? {
        return try? unkeyedMapperValue(forKeyPath: keyPath)
    }
    
    // MARK: - Transforms -
    
    public func transformValue<T, U>(forKeyPath keyPath: Key, block: (T) throws -> U) throws -> U {
        guard let value = self.value(forKeyPath: keyPath) else {
            throw Mapper.Error.keyPathMissing(key: keyPath, debugDescription: "No value associated with keyPath \(keyPath)")
        }
        
        guard let newValue = value as? T else {
            throw Mapper.Error.invalidType(key: keyPath,
                                           expected: T.self,
                                           actual: type(of: value),
                                           debugDescription: "Expected \(T.self) value but found \(type(of: value)) instead.")
        }
        
        return try block(newValue)
    }
    
    public func transform<T, U>(forKeyPath keyPath: Key, block: (T) throws -> U) -> U? {
        return try? transformValue(forKeyPath: keyPath, block: block)
    }
}
