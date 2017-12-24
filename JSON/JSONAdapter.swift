//
//  JSONAdapter.swift
//  JSON
//
//  Created by Juan Alvarez on 12/23/17.
//  Copyright © 2017 Alvarez Productions. All rights reserved.
//

import Foundation

public final class JSONAdapter<N: JSONMappable> {
    
    public enum Error: Swift.Error {
        case invalidJSON
    }
    
    private init() {}
    
    public class func objectFromJSONDictionary(dict: JSONDict) -> N {
        let mapper = JSONMapper(dictionary: dict)
        let object = N(mapper: mapper)
        
        return object
    }
    
    public class func objectsFromJSONArray(array: JSONArray) -> [N] {
        let results = array.map({ (json: JSONDict) -> N in
            return self.objectFromJSONDictionary(dict: json)
        })
        
        return results
    }
    
    public class func objectsFromJSONFile(url: URL) throws -> [N] {
        let data = try Data(contentsOf: url)
        
        return try objectsFromJSONData(data: data)
    }
    
    public class func objectsFromJSONData(data: Data) throws -> [N] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        if let dict = json as? JSONDict {
            return [objectFromJSONDictionary(dict: dict)]
        }
        
        if let array = json as? JSONArray {
            return objectsFromJSONArray(array: array)
        }
        
        throw Error.invalidJSON
    }
    
    public class func objectsFrom(array: [AnyObject]) -> [N]? {
        if let array = array as? JSONArray {
            return objectsFromJSONArray(array: array)
        }
        
        return nil
    }
    
    public class func objectsValueFrom(array: [AnyObject]) -> [N] {
        if let array = objectsFrom(array: array) {
            return array
        }
        
        return []
    }
    
    public class func objectFrom(object: AnyObject) -> N? {
        if let dict = object as? JSONDict {
            return objectFromJSONDictionary(dict: dict)
        }
        
        return nil
    }
}
