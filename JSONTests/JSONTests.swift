//
//  JSONTests.swift
//  JSONTests
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import UIKit
import XCTest

class JSONTests: XCTestCase {
    
    enum TestEnum: String {
        case One = "one"
        case Two = "two"
    }
    
    let testDict: JSONDict = [
        "string": "test_string",
        "int": 277,
        "bool": true,
        "double": 922,
        "float": 0.98,
        "array": ["string1", "string2", "string3"],
        "set": ["string1", "string2", "string3"],
        "dictionary": ["key": "value"],
        "enum": ["one", "two", "three"]
    ]
    
    lazy var testDictArray: JSONArray = {
        var testDictArray = JSONArray()
        
        for _ in 0..<10000 {
            testDictArray.append(self.testDict)
        }
        
        return testDictArray
    }()
    
    struct TestObject: JSONMappable {
        let string: String
        let int: Int
        let bool: Bool
        let double: Double
        let float: Float
        let array: [String]
        let dictionary: JSONDict
        let enums: [TestEnum]
        
        init(mapper: JSONMapper) throws {
            string = try mapper.decodeValue(forKeyPath: "string")
            int = try mapper.decodeValue(forKeyPath: "int")
            bool = try mapper.decodeValue(forKeyPath: "bool")
            double = try mapper.decodeValue(forKeyPath: "double")
            float = try mapper.decodeValue(forKeyPath: "float")
            array = try mapper.decodeValue(forKeyPath: "array")
            dictionary = try mapper.decodeValue(forKeyPath: "dictionary")
            
            enums = mapper.flatMapArrayValueFor(keyPath: "enum", block: { (value) -> TestEnum? in
                return TestEnum(rawValue: value)
            })
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        _ = testDictArray
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testPerformance() {
//        self.measure() {
//            _ = try! JSONAdapter.objectsFromJSONArray(array: self.testDictArray)
//        }
//    }
//    
//    func testGetValuePerformance() {
//        let mappers = testDictArray.map { return JSONMapper(dictionary: $0)}
//        
//        self.measure { () -> Void in
//            for mapper in mappers {
//                _ = mapper.flatMapArrayValueFor(keyPath: "enum", block: { (value) -> TestEnum? in
//                    return TestEnum(rawValue: value)
//                })
//            }
//        }
//    }
}
