//
//  Key.swift
//  JSON
//
//  Created by Juan Alvarez on 1/17/19.
//  Copyright © 2019 Alvarez Productions. All rights reserved.
//

import Foundation

public protocol Key {
    func stringValue() -> String
    func keys() -> [String]
}

extension String: Key {
    
    public func stringValue() -> String {
        return self
    }
    
    public func keys() -> [String] {
        return [self]
    }
}

public extension RawRepresentable where RawValue == String {
    
    func stringValue() -> String {
        return self.rawValue
    }
    
    func keys() -> [String] {
        return [self.rawValue]
    }
}

extension Array: Key where Element == String {
    
    public func stringValue() -> String {
        return self.map { $0 }.joined(separator: ".")
    }
    
    public func keys() -> [String] {
        return self
    }
}
