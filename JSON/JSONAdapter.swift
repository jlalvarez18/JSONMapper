//
//  JSONAdapter.swift
//  JSON
//
//  Created by Juan Alvarez on 12/23/17.
//  Copyright © 2017 Alvarez Productions. All rights reserved.
//

import Foundation

public final class JSONAdapter {
    
    public enum Error: Swift.Error {
        case invalidJSONType(actual: Any.Type)
        case invalidInput
    }
    
    struct Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let valueDecodingStrategy: ValueDecodingStrategy
        let keyDecodingStrategy: KeyDecodingStrategy
    }
    
    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy {
        /// Decode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970
        
        /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970
        
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format). This is the default strategy.
        case iso8601
        
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((Any) throws -> Date)
    }
    
    /// The strategy to use for decoding `Data` values.
    public enum DataDecodingStrategy {
        /// Decode the `Data` from a Base64-encoded string. This is the default strategy.
        case base64
        
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((Any) throws -> Data)
    }
    
    public enum ValueDecodingStrategy {
        /// If value is not present, default values will be used when calling decodeValue().
        /// This only works for JSONType, JSONDict, JSONArray and Bool values.
        /// This is the default strategy.
        case useDefaultValues
        
        /// If value is not present or value is not of the same type, decodeValue() will throw an error
        case `throw`
    }
    
    public enum KeyDecodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Convert from "camelCaseKeys" to "snake_case_keys"
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case convertToSnakeCase
        
        func convert(_ key: String) -> String {
            switch self {
            case .useDefaultKeys:
                return key
                
            case .convertToSnakeCase:
                guard key.count > 0 else {
                    return key
                }
                
                let pattern = "([a-z0-9])([A-Z])"
                
                let regex = try! NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: key.count)
                
                return regex.stringByReplacingMatches(in: key, options: [], range: range, withTemplate: "$1_$2").lowercased()
            }
        }
    }
    
    /// The strategy to use in decoding dates. Defaults to `.iso8601`.
    public var dateDecodingStrategy: JSONAdapter.DateDecodingStrategy = .iso8601
    
    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    public var dataDecodingStrategy: JSONAdapter.DataDecodingStrategy = .base64
    
    public var valueDecodingStrategy: JSONAdapter.ValueDecodingStrategy = .useDefaultValues
    
    public var keyDecodingStrategy: JSONAdapter.KeyDecodingStrategy = .useDefaultKeys
    
    fileprivate var options: Options {
        return Options(dateDecodingStrategy: dateDecodingStrategy,
                       dataDecodingStrategy: dataDecodingStrategy,
                       valueDecodingStrategy: valueDecodingStrategy,
                       keyDecodingStrategy: keyDecodingStrategy)
    }
    
    public func decode<T: JSONMappable>(data: Data) throws -> T {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        let mapper = JSONMapper(value: json, keyPath: [], options: self.options)
        
        let object = try T(mapper: mapper)
        
        return object
    }
    
    public func decode<T: JSONMappable>(jsonString: String) throws -> T {
        guard let data = jsonString.data(using: .utf8) else {
            throw Error.invalidInput
        }
        
        return try decode(data: data)
    }
    
    public func decode<T: JSONMappable>(fileUrl: URL) throws -> T {
        let data = try Data(contentsOf: fileUrl)
        
        return try decode(data: data)
    }
    
    public func decode<T: JSONMappable>(value: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decode(data: data)
    }
}
