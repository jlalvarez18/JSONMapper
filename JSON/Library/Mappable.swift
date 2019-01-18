//
//  Mappable.swift
//  JSON
//
//  Created by Juan Alvarez on 2/21/18.
//  Copyright © 2018 Alvarez Productions. All rights reserved.
//

import Foundation

public protocol Mappable {
    init(mapper: Mapper) throws
}

// MARK: - Array of Mappables -

extension Array: Mappable where Element: Mappable {
    
    public init(mapper: Mapper) throws {
        self.init()
        
        let container = try mapper.unkeyedMapperValue()
        
        let values = container.rawValue
        
        for value in values {
            let mapper = Mapper(value: value, keyPath: mapper.keyPath, options: mapper.options)
            
            let item = try Element(mapper: mapper)
            
            self.append(item)
        }
    }
}

// MARK: - Dictionary -

extension Dictionary: Mappable where Key == String, Value == Any {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.keyedMapperValue()
        
        self = container.rawValue
    }
}

// MARK: - RawRepresentable -

extension RawRepresentable {
    
    init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        guard let newValue = value as? RawValue else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: RawValue.self, value: value)
        }
        
        guard let rep = Self(rawValue: newValue) else {
            throw Mapper.Error.dataCorrupted(key: mapper.keyPath, actual: newValue, debugDescription: "Unable to initialize \(Self.self) with value: \(newValue)")
        }
        
        self = rep
    }
}

extension String: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        guard let newValue = container.rawValue as? String else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: String.self, value: container.rawValue)
        }
        
        self = newValue
    }
}

// MARK: - Data -

extension Data: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        switch mapper.dataDecodingStrategy {
        case .base64:
            let value: String = try container.decodeValue()
            
            guard let data = Data(base64Encoded: value) else {
                throw Mapper.Error.dataCorrupted(key: mapper.keyPath, actual: value, debugDescription: "Encountered Data is not valid Base64.")
            }
            
            self = data
            
        case .custom(let block):
            self = try block(container.rawValue)
        }
    }
}

// MARK: - URL -

extension URL: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let urlString: String = try container.decodeValue()
        
        guard let url = URL(string: urlString) else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: urlString, debugDescription: "Invalid URL string.")
        }
        
        self = url
    }
}

// MARK: - Bool -

extension Bool: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let boolValue: Bool?
        
        if let _value = value as? Bool {
            boolValue = _value
        } else if let stringValue = value as? String {
            switch stringValue.lowercased() {
            case "true", "yes", "1":
                boolValue = true
                
            case "false", "no", "0":
                boolValue = false
                
            default:
                boolValue = nil
            }
        } else if let number = value as? NSNumber {
            if (number == kCFBooleanTrue) {
                boolValue = true
            } else if (number == kCFBooleanFalse) {
                boolValue = false
            } else {
                boolValue = nil
            }
        } else {
            boolValue = nil
        }
        
        guard let finalValue = boolValue else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: Bool.self, value: value)
        }
        
        self = finalValue
    }
}

// MARK: - Date -

private let _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()

extension Date: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        switch mapper.dateDecodingStrategy {
        case .formatted(let formatter):
            let value: String = try container.decodeValue()
            
            guard let date = formatter.date(from: value) else {
                throw Mapper.Error.dataCorrupted(key: mapper.keyPath, actual: value, debugDescription: "Date string does not match format expected by formatter.")
            }
            
            self = date
        case .secondsSince1970:
            let value: Double = try container.decodeValue()
            
            self = Date(timeIntervalSince1970: value)
            
        case .millisecondsSince1970:
            let value: Double = try container.decodeValue()
            
            self = Date(timeIntervalSince1970: value/1000.0)
            
        case .iso8601:
            let value: String = try container.decodeValue()
            
            guard let date = _iso8601Formatter.date(from: value) else {
                throw Mapper.Error.dataCorrupted(key: mapper.keyPath, actual: value, debugDescription: "Expected date string to be ISO8601-formatted.")
            }
            
            self = date
            
        case .custom(let block):
            self = try block(container.rawValue)
        }
    }
}

// MARK: - Numbers -

private func isNotBoolean(number: NSNumber) -> Bool {
    return number !== kCFBooleanFalse && number !== kCFBooleanTrue
}

extension Int: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Int.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.intValue
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension Int8: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Int8.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.int8Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension Int16: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Int16.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.int16Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension Int32: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Int32.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.int32Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension Int64: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Int64.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.int64Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension UInt: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = UInt.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.uintValue
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension UInt8: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = UInt8.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.uint8Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension UInt16: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = UInt16.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.uint16Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension UInt32: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = UInt32.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.uint32Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension UInt64: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = UInt64.self
        
        guard let number = value as? NSNumber, isNotBoolean(number: number) else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
        
        let newValue = number.uint64Value
        
        guard NSNumber(value: newValue) == number else {
            throw mapper.dataCorrupted(mapper.keyPath, actual: newValue, debugDescription: "Parsed JSON number \(newValue) does not fit in \(type)")
        }
        
        self = newValue
    }
}

extension Double: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Double.self
        
        let newValue: Double?
        
        if let number = value as? NSNumber, isNotBoolean(number: number) {
            let double = number.doubleValue
            
            guard NSNumber(value: double) == number else {
                throw mapper.dataCorrupted(mapper.keyPath, actual: double, debugDescription: "Parsed JSON number \(double) does not fit in \(type)")
            }
            
            newValue = double
        } else if let string = value as? String {
            switch mapper.options.nonConformingFloatDecodingStrategy {
            case .convertFromString(let positiveInfinity, let negativeInfinity, let nan):
                if string == positiveInfinity {
                    newValue = Double.infinity
                } else if string == negativeInfinity {
                    newValue = -Double.infinity
                } else if string == nan {
                    newValue = Double.nan
                } else {
                    newValue = nil
                }
            case .throw:
                newValue = nil
            }
        } else {
            newValue = nil
        }
        
        if let _newValue = newValue {
            self = _newValue
        } else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
    }
}

extension Float: Mappable {
    
    public init(mapper: Mapper) throws {
        let container = try mapper.singleMapperValue()
        
        let value = container.rawValue
        
        let type = Float.self
        
        let newValue: Float?
        
        if let number = value as? NSNumber, isNotBoolean(number: number) {
            let double = number.doubleValue
            
            // We are willing to return a Float by losing precision:
            // * If the original value was integral,
            //   * and the integral value was > Float.greatestFiniteMagnitude, we will fail
            //   * and the integral value was <= Float.greatestFiniteMagnitude, we are willing to lose precision past 2^24
            // * If it was a Float, you will get back the precise value
            // * If it was a Double or Decimal, you will get back the nearest approximation if it will fit
            
            guard abs(double) <= Double(Float.greatestFiniteMagnitude) else {
                throw mapper.dataCorrupted(mapper.keyPath, actual: double, debugDescription: "Parsed JSON number \(double) does not fit in \(type)")
            }
            
            newValue = Float(double)
        } else if let string = value as? String {
            switch mapper.options.nonConformingFloatDecodingStrategy {
            case .convertFromString(let positiveInfinity, let negativeInfinity, let nan):
                if string == positiveInfinity {
                    newValue = Float.infinity
                } else if string == negativeInfinity {
                    newValue = -Float.infinity
                } else if string == nan {
                    newValue = Float.nan
                } else {
                    newValue = nil
                }
            case .throw:
                newValue = nil
            }
        } else {
            newValue = nil
        }
        
        if let _newValue = newValue {
            self = _newValue
        } else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: type, value: value)
        }
    }
}
