//
//  JSONAdapter.swift
//  JSON
//
//  Created by Juan Alvarez on 12/23/17.
//  Copyright © 2017 Alvarez Productions. All rights reserved.
//

import Foundation

public final class Adapter {
    
    public enum Error: Swift.Error {
        case invalidJSONType(actual: Any.Type)
        case invalidInput
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
    
    /// The strategy to use for non-JSON-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatDecodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    /// The strategy to use in decoding dates. Defaults to `.iso8601`.
    public var dateDecodingStrategy: DateDecodingStrategy = .iso8601
    
    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    public var dataDecodingStrategy: DataDecodingStrategy = .base64
    
    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    public var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
    
    /// The strategy to use in decoding non-conforming numbers. Defaults to `.throw`
    public var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
    
    struct Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let keyDecodingStrategy: KeyDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
    }
    
    fileprivate var options: Options {
        return Options(dateDecodingStrategy: dateDecodingStrategy,
                       dataDecodingStrategy: dataDecodingStrategy,
                       keyDecodingStrategy: keyDecodingStrategy,
                       nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy)
    }
    
    public func decode<T: Mappable>(data: Data) throws -> T {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        let mapper = Mapper(value: json, keyPath: [], options: self.options)
        
        let object = try T(mapper: mapper)
        
        return object
    }
    
    public func decode<T: Mappable>(jsonString: String) throws -> T {
        guard let data = jsonString.data(using: .utf8) else {
            throw Error.invalidInput
        }
        
        return try decode(data: data)
    }
    
    public func decode<T: Mappable>(fileUrl: URL) throws -> T {
        let data = try Data(contentsOf: fileUrl)
        
        return try decode(data: data)
    }
    
    public func decode<T: Mappable>(value: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        
        return try decode(data: data)
    }
}
