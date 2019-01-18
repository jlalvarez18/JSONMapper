//
//  UnkeyedMapper.swift
//  JSON
//
//  Created by Juan Alvarez on 1/17/19.
//  Copyright © 2019 Alvarez Productions. All rights reserved.
//

import Foundation

public struct UnkeyedMapper {
    public let keyPath: Key
    
    private let mapper: Mapper
    
    public let rawValue: [Any]
    
    init(mapper: Mapper, wrapping container: [Any]) {
        self.mapper = mapper
        self.rawValue = container
        self.keyPath = mapper.keyPath
    }
    
    public var count: Int {
        return self.rawValue.count
    }
    
    // MARK: - Mappable Values -
    
    public func decodeValue<T>() throws -> T where T: Mappable {
        let newMapper = Mapper(value: self.rawValue, keyPath: self.keyPath, options: self.mapper.options)
        
        return try T(mapper: newMapper)
    }
    
    public func decode<T>() -> T? where T: Mappable {
        return try? decodeValue()
    }
    
    // MARK: - Decodable values -
    
    public func decodeValue<T>(decoder: JSONDecoder) throws -> T where T: Decodable {
        let data = try JSONSerialization.data(withJSONObject: self.rawValue, options: [])
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decode<T>(decoder: JSONDecoder) -> T? where T: Decodable {
        return try? decodeValue(decoder: decoder)
    }
    
    // MARK: - Transforms -
    
    public func transformValue<T, U>(forKeyPath keyPath: Key, block: (T) throws -> U) throws -> [U] {
        guard self.count > 0 else {
            return []
        }
        
        guard let value = self.rawValue as? [T] else {
            throw Mapper.Error.invalidType(key: keyPath,
                                           expected: T.self,
                                           actual: type(of: self.rawValue),
                                           debugDescription: "Expected \(T.self) value but found \(type(of: self.rawValue)) instead.")
        }
        
        let newValue = try value.map(block)
        
        return newValue
    }
    
    public func transform<T, U>(forKeyPath keyPath: Key, block: (T) throws -> U) -> [U]? {
        return try? transformValue(forKeyPath: keyPath, block: block)
    }
}
