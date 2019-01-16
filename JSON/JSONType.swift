//
//  JSONType.swift
//  JSON
//
//  Created by Juan Alvarez on 1/16/19.
//  Copyright © 2019 Alvarez Productions. All rights reserved.
//

import Foundation

public protocol JSONType {
    static func defaultValue() -> Self
}

extension Array: JSONType where Element: JSONType {
    
    public init(mapper: JSONMapper) throws {
        self.init()
        
        let values: [Any] = try mapper.decodeValue()
        
        for value in values {
            let itemMapper = JSONMapper(value: value, keyPath: [], options: mapper.options)
            
            let item: Element = try itemMapper.decodeValue()
            
            self.append(item)
        }
    }
    
    public static func defaultValue() -> Array<Element> {
        return []
    }
}

extension String: JSONType {
    static public func defaultValue() -> String {
        return ""
    }
}

extension Int: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.intValue
    }
}

extension Int8: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.int8Value
    }
}

extension Int16: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.int16Value
    }
}

extension Int32: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.int32Value
    }
}

extension Int64: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.int64Value
    }
}

extension UInt: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.uintValue
    }
}

extension UInt8: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.uint8Value
    }
}

extension UInt16: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.uint16Value
    }
}

extension UInt32: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.uint32Value
    }
}

extension UInt64: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.uint64Value
    }
}

extension Double: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.doubleValue
    }
}

extension Float: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let number = value as? NSNumber else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: NSNumber.self, value: value)
        }
        
        self = number.floatValue
    }
}
