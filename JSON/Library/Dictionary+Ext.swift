//
//  Dictionary+Ext.swift
//  JSON
//
//  Created by Juan Alvarez on 1/16/19.
//  Copyright © 2019 Alvarez Productions. All rights reserved.
//

import Foundation

extension Dictionary {
    
    public func value(forKeyPath keyPath: String...) -> Any? {
        return value(forKeyPath: keyPath)
    }
    
    public func value(forKeyPath keys: [String]) -> Any? {
        var newKeys = keys.flatMap { $0.components(separatedBy: ".") }
        
        guard let first = newKeys.first as? Key else {
            print("Unable to use string as key on type: \(Key.self)")
            return nil
        }
        
        guard let value = self[first] else {
            return nil
        }
        
        newKeys.remove(at: 0)
        
        if !newKeys.isEmpty, let subDict = value as? [String: Any] {
            let rejoined = newKeys.joined(separator: ".")
            
            return subDict.value(forKeyPath: rejoined)
        }
        
        return value
    }
    
    mutating public func set(value: Any, forKeyPath keyPath: String...) {
        set(value: value, forKeyPath: keyPath)
    }
    
    mutating public func set(value: Any, forKeyPath keyPath: [String]) {
        var keys = keyPath
        
        guard let first = keys.first as? Key else {
            print("Unable to use string as key on type: \(Key.self)")
            return
        }
        
        keys.remove(at: 0)
        
        if keys.isEmpty, let val = value as? Value {
            self[first] = val
        } else {
            let rejoined = keys.joined(separator: ".")
            
            var subDict: [AnyHashable: Any] = [:]
            
            if let sub = self[first] as? Dictionary {
                subDict = sub
            }
            
            subDict.set(value: value, forKeyPath: rejoined)
            
            if let val = subDict as? Value {
                self[first] = val
            } else {
                print("Unable to set value: \(subDict) to dictionary of type: \(type(of: self))")
            }
        }
    }
}
