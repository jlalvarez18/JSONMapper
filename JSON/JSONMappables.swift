//
//  JSONMappables.swift
//  JSON
//
//  Created by Juan Alvarez on 2/21/18.
//  Copyright © 2018 Alvarez Productions. All rights reserved.
//

import Foundation

// MARK: - RawRepresentable -

extension RawRepresentable {
    
    init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
        guard let newValue = value as? RawValue else {
            throw mapper.invalidTypeError(mapper.keyPath, expected: RawValue.self, value: value)
        }
        
        guard let rep = Self(rawValue: newValue) else {
            throw JSONMapper.Error.dataCorrupted(key: mapper.keyPath, actual: newValue, debugDescription: "Unable to initialize \(Self.self) with value: \(newValue)")
        }
        
        self = rep
    }
}

// MARK: - Data -

extension Data: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        switch mapper.dataDecodingStrategy {
        case .base64:
            let value: String = try mapper.decodeValue()
            
            guard let data = Data(base64Encoded: value) else {
                throw JSONMapper.Error.dataCorrupted(key: mapper.keyPath, actual: value, debugDescription: "Encountered Data is not valid Base64.")
            }
            
            self = data
            
        case .custom(let block):
            let value: Any = try mapper.decodeValue()
            
            self = try block(value)
        }
    }
}

// MARK: - URL -

extension URL: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let urlString: String = try mapper.decodeValue()
        
        guard let url = URL(string: urlString) else {
            throw JSONMapper.Error.dataCorrupted(key: mapper.keyPath, actual: urlString, debugDescription: "Invalid URL string.")
        }
        
        self = url
    }
}

// MARK: - Bool -

extension Bool: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let value: Any = try mapper.decodeValue()
        
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

extension Date: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        switch mapper.dateDecodingStrategy {
        case .formatted(let formatter):
            let value: String = try mapper.decodeValue()
            
            guard let date = formatter.date(from: value) else {
                throw JSONMapper.Error.dataCorrupted(key: mapper.keyPath, actual: value, debugDescription: "Date string does not match format expected by formatter.")
            }
            
            self = date
        case .secondsSince1970:
            let value: Double = try mapper.decodeValue()
            
            self = Date(timeIntervalSince1970: value)
            
        case .millisecondsSince1970:
            let value: Double = try mapper.decodeValue()
            
            self = Date(timeIntervalSince1970: value/1000.0)
            
        case .iso8601:
            let value: String = try mapper.decodeValue()
            
            guard let date = _iso8601Formatter.date(from: value) else {
                throw JSONMapper.Error.dataCorrupted(key: mapper.keyPath, actual: value, debugDescription: "Expected date string to be ISO8601-formatted.")
            }
            
            self = date
            
        case .custom(let block):
            let value: Any = try mapper.decodeValue()
            
            self = try block(value)
        }
    }
}
