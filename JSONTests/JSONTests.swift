//
//  JSONTests.swift
//  JSONTests
//
//  Created by Juan Alvarez on 2/11/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import XCTest
@testable import JSON

class JSONTests: XCTestCase {
    
    lazy var adapter: Adapter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        
        let adapter = Adapter()
        adapter.dateDecodingStrategy = .formatted(dateFormatter)
        adapter.keyDecodingStrategy = .convertToSnakeCase
        
        return adapter
    }()
    
    enum MyEnum: String, Mappable {
        case One = "one"
        case Two = "two"
    }
    
    let testDict: [String: Any] = [
        "string": "test_string",
        "int": 277,
        "bool": true,
        "double": 922.0,
        "float": 0.98,
        "array": [
            "string": ["string1", "string2", "string3"],
            "int": [1,2,3,4],
            "float": [0.1, 0.2],
            "enum": ["one", "two"]
        ],
        "set": ["string1", "string2", "string3"],
        "dictionary": ["key": "value"],
        "enum": "two",
        "date": "Thu Feb 12 15:26:30 +0000 2015",
        "color": "0084B4"
    ]
    
    lazy var testDictArray: [[String: Any]] = {
        var testDictArray = [[String: Any]]()
        
        for _ in 0..<10 {
            testDictArray.append(self.testDict)
        }
        
        return testDictArray
    }()
    
    struct TestObject: Mappable {
        let string: String
        let int: Int
        let bool: Bool
        let double: Double
        let float: Float
        let dictionary: [String: Any]
        let enumValue: MyEnum
        let date: Date
        let color: UIColor?
        
        let stringArray: [String]
        let intArray: [Int]
        let floatArray: [Float]
        let enumArray: [MyEnum]
        
        enum Keys: String, Key {
            case string
            case int
            case bool
            case double
            case float
            case dictionary
            case enumValue = "enum"
            case date
            case color
            
            case stringArray = "array.string"
            case intArray = "array.int"
            case floatArray = "array.float"
            case enumArray = "array.enum"
        }
        
        init(mapper: Mapper) throws {
            let container = try mapper.keyedMapperValue()
            
            string = try container.decodeValue(forKeyPath: Keys.string)
            int = try container.decodeValue(forKeyPath: Keys.int)
            bool = try container.decodeValue(forKeyPath: Keys.bool)
            double = try container.decodeValue(forKeyPath: Keys.double)
            float = try container.decodeValue(forKeyPath: Keys.float)
            dictionary = try container.decodeValue(forKeyPath: Keys.dictionary)
            enumValue = try container.decodeValue(forKeyPath: Keys.enumValue)
            date = try container.decodeValue(forKeyPath: Keys.date)
            
            color = {
                guard let value: String = container.decode(forKeyPath: Keys.color) else {
                    return nil
                }
                
                return UIColor.fromHex(hex: value)
            }()
            
            stringArray = try container.decodeValue(forKeyPath: Keys.stringArray)
            intArray = try container.decodeValue(forKeyPath: Keys.intArray)
            floatArray = try container.decodeValue(forKeyPath: Keys.floatArray)
            enumArray = try container.decodeValue(forKeyPath: Keys.enumArray)
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMapper() {
        do {
            let items: [TestObject] = try adapter.decode(value: self.testDictArray)
            
            XCTAssertEqual(items.count, 10)
            
            let desc = deepDescription(items.first!)
            print(desc)
        } catch {
            print(error)
            
            XCTFail()
        }
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
