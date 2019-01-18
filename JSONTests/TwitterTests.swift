//
//  TwitterTests.swift
//  JSONTests
//
//  Created by Juan Alvarez on 2/25/18.
//  Copyright © 2018 Alvarez Productions. All rights reserved.
//

import XCTest
@testable import JSON

class TwitterTests: XCTestCase {
    
    lazy var tweetsJSONURL: URL = {
        let url = Bundle.main.url(forResource: "tweets", withExtension: "json")!
        return url
    }()
    
    lazy var adapter: Adapter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        
        let adapter = Adapter()
        adapter.dateDecodingStrategy = .formatted(dateFormatter)
        adapter.keyDecodingStrategy = .convertToSnakeCase
        
        return adapter
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFullDecoding() {
        do {
            let data = try Data(contentsOf: self.tweetsJSONURL)
            let tweets: [Tweet] = try self.adapter.decode(data: data)
            
            XCTAssertEqual(tweets.count, 20)
            
            let desc = deepDescription(tweets.first!)
            print(desc)
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testTweetDecoding() {
        do {
            let data = try Data(contentsOf: self.tweetsJSONURL)
            let tweets: [Tweet] = try self.adapter.decode(data: data)
            
            guard let tweet = tweets.first else {
                XCTFail("Tweets did not decode")
                return
            }
            
            XCTAssertNotNil(tweet.createdAt)
            
            XCTAssertEqual(tweet.text, "#DIY recipe for a natural safe #antibacterial, #antiviral and #antifungal #tonic: http://t.co/9YyhXpV43C")
            XCTAssertEqual(tweet.screenName, "HealthRanger")
            XCTAssertEqual(tweet.createdAt, Date(timeIntervalSince1970: 1423754790.0))
            XCTAssertEqual(tweet.favorited, false)
            XCTAssertEqual(tweet.language, Tweet.Language.english)
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testTweetUserDecoding() {
        do {
            let data = try Data(contentsOf: self.tweetsJSONURL)
            let tweets: [Tweet] = try self.adapter.decode(data: data)
            
            guard let user = tweets.first?.user else {
                XCTFail("Tweets did not decode")
                return
            }
            
            XCTAssertNotNil(user.createdAt)
            
            XCTAssertEqual(user.name, "HealthRanger")
            XCTAssertEqual(user.id, 15843059)
            XCTAssertEqual(user.idString, "15843059")
            XCTAssertEqual(user.createdAt, Date(timeIntervalSince1970: 1218664943.0))
            XCTAssertEqual(user.url, URL(string: "http://t.co/Esaj5gcemr"))
            XCTAssertEqual(user.defaultProfile, true)
            XCTAssertEqual(user.followersCount, 87823)
            XCTAssertEqual(user.urlItems.count, 2)
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testTweetUserURLItemsDecoding() {
        do {
            let data = try Data(contentsOf: self.tweetsJSONURL)
            let tweets: [Tweet] = try self.adapter.decode(data: data)
            
            guard let user = tweets.first?.user else {
                XCTFail("Tweets did not decode")
                return
            }
            
            let urlItems = user.urlItems
            
            guard urlItems.count == 2 else {
                XCTFail("Invalid amout of urlItems")
                return
            }
            
            let item = urlItems.first!
            
            XCTAssertEqual(item.displayURL, "NaturalNews.com")
            XCTAssertEqual(item.expandedURL, URL(string: "http://www.NaturalNews.com"))
            XCTAssertEqual(item.url, URL(string: "http://t.co/Esaj5gcemr"))
            XCTAssertEqual(item.indices, [39, 61])
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testPerformanceExample() {
        let data = try! Data(contentsOf: self.tweetsJSONURL)
        
        self.measure {
            do {
                let _: [Tweet] = try self.adapter.decode(data: data)
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
}
