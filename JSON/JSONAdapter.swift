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
    }
    
    struct Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let valueDecodingStrategy: ValueDecodingStrategy
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
    
    /// The strategy to use in decoding dates. Defaults to `.iso8601`.
    public var dateDecodingStrategy: JSONAdapter.DateDecodingStrategy = .iso8601
    
    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    public var dataDecodingStrategy: JSONAdapter.DataDecodingStrategy = .base64
    
    public var valueDecodingStrategy: JSONAdapter.ValueDecodingStrategy = .useDefaultValues
    
    fileprivate var options: Options {
        return Options(dateDecodingStrategy: dateDecodingStrategy,
                       dataDecodingStrategy: dataDecodingStrategy,
                       valueDecodingStrategy: valueDecodingStrategy)
    }
    
    public func decode<T: JSONMappable>(data: Data) throws -> T {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        let mapper = JSONMapper(value: json, keyPath: nil, options: self.options)
        
        let object = try T(mapper: mapper)
        
        return object
    }
    
    public func decode<T: JSONMappable>(data: Data) throws -> [T] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let array = json as? [Any] else {
            throw Error.invalidJSONType(actual: type(of: json))
        }
        
        let results = try array.map { (value) -> T in
            let mapper = JSONMapper(value: value, keyPath: nil, options: self.options)
            return try T(mapper: mapper)
        }
        
        return results
    }
    
    public func decode<T: JSONMappable>(fileUrl: URL) throws -> T {
        let data = try Data(contentsOf: fileUrl)
        
        return try decode(data: data)
    }
    
    public func decode<T: JSONMappable>(fileUrl: URL) throws -> [T] {
        let data = try Data(contentsOf: fileUrl)
        
        return try decode(data: data)
    }
}
