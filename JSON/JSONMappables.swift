//
//  JSONMappables.swift
//  JSON
//
//  Created by Juan Alvarez on 2/21/18.
//  Copyright © 2018 Alvarez Productions. All rights reserved.
//

import Foundation

// MARK: - Data -

extension Data: JSONMappable {
    public init(mapper: JSONMapper) throws {
        switch mapper.dataDecodingStrategy {
        case .base64:
            let value: String = try mapper.decodeValue()
            
            guard let data = Data(base64Encoded: value) else {
                throw JSONMapper.Error.dataCorrupted(mapper.keyPath)
            }
            
            self = data
            
        case .custom(let block):
            guard let value = mapper.rawValue else {
                throw JSONMapper.Error.dataCorrupted(mapper.keyPath)
            }
            
            self = try block(value)
        }
    }
}

// MARK: - URL -

extension URL: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        let urlString: String = try mapper.decodeValue()
        
        guard let url = URL(string: urlString) else {
            throw JSONMapper.Error.dataCorrupted(mapper.keyPath)
        }
        
        self = url
    }
}

// MARK: - Bool -

extension Bool: JSONMappable {
    
    public init(mapper: JSONMapper) throws {
        guard let value = mapper.rawValue else {
            switch mapper.valueDecodingStrategy {
            case .useDefaultValues:
                self = false
            case .throw:
                throw JSONMapper.Error.keyPathMissing(mapper.keyPath)
            }
            return
        }
        
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
            throw JSONMapper.Error.invalidType(expected: Bool.self, actual: type(of: value))
        }
        
        self = finalValue
    }
}

// MARK: - Date -

private let iso8601: ISO8601DateFormatter = {
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
                throw JSONMapper.Error.dataCorrupted(mapper.keyPath)
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
            
            guard let date = iso8601.date(from: value) else {
                throw JSONMapper.Error.dataCorrupted(mapper.keyPath)
            }
            
            self = date
            
        case .custom(let block):
            guard let value = mapper.rawValue else {
                throw JSONMapper.Error.dataCorrupted(mapper.keyPath)
            }
            
            self = try block(value)
        }
    }
}
