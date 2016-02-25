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
        let array: Array<String>
        let set: Set<String>
        let dictionary: JSONDict
        let enums: [TestEnum]
        
        init(mapper: JSONMapper) {
            string = mapper.stringValueFor("string")
            int = mapper.intValueFor("int")
            bool = mapper.boolValueFor("bool")
            double = mapper.doubleValueFor("double")
            float = mapper.floatValueFor("float")
            array = mapper.arrayValueFor("array")
            set = mapper.setValueFor("set")
            dictionary = mapper.dictionaryValueFor("dictionary")
            
            enums = mapper.flatMapArrayValueFor("enum", block: { (value) -> TestEnum? in
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
    
    func testPerformance() {
        self.measureBlock() {
            _ = JSONAdapter<TestObject>.objectsFromJSONArray(self.testDictArray)
        }
    }
    
    func testGetValuePerformance() {
        let mappers = testDictArray.map { return JSONMapper(dictionary: $0)}
        
        self.measureBlock { () -> Void in
            for mapper in mappers {
                mapper.flatMapArrayValueFor("enum", block: { (value) -> TestEnum? in
                    return TestEnum(rawValue: value)
                })
            }
        }
    }
}
