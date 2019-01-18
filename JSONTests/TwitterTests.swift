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

struct Tweet: Mappable {
    let user: User
    let text: String
    let screenName: String
    let createdAt: Date
    let favorited: Bool
    let language: Language?
    let urlItems: [URLItem]
    let replyToStatus: Int?
    
    enum Language: String, Mappable {
        case english = "en"
        case french = "fr"
        case spanish = "es"
    }
    
    enum Keys: String, Key {
        case user
        case text
        case createdAt
        case favorited
        case language = "lang"
        case urlItems = "entities.urls"
        case replayToStatusId = "in_reply_to_status_id"
    }
    
    init(mapper: Mapper) throws {
        let container = try mapper.keyedMapperValue()
        
        language = container.decode(forKeyPath: Keys.language)
        user = try container.decodeValue(forKeyPath: Keys.user)
        screenName = try container.decodeValue(forKeyPath: ["user", "screen_name"])
        text = try container.decodeValue(forKeyPath: Keys.text)
        createdAt = try container.decodeValue(forKeyPath: Keys.createdAt)
        favorited = try container.decodeValue(forKeyPath: Keys.favorited)
        urlItems = try container.decodeValue(forKeyPath: Keys.urlItems, decoder: JSONDecoder())
        replyToStatus = container.decode(forKeyPath: Keys.replayToStatusId)
    }
}

struct User: Mappable {
    let name: String
    let idString: String
    let id: Int
    let createdAt: Date
    let url: URL?
    let urlItems: [URLItem]
    let defaultProfile: Bool
    let followersCount: Int
    let description: String
    let backgroundColor: UIColor?
    
    enum Keys: String, Key {
        case name
        case idString = "id_str"
        case id
        case createdAt = "created_at"
        case url
        case urlItems = "entities.description.urls"
        case defaultProfile = "default_profile"
        case followersCount = "followers_count"
        case description
        case backgroundColor = "profile_background_color"
    }
    
    init(mapper: Mapper) throws {
        let container = try mapper.keyedMapperValue()
        
        name = try container.decodeValue(forKeyPath: Keys.name)
        idString = try container.decodeValue(forKeyPath: Keys.idString)
        id = try container.decodeValue(forKeyPath: Keys.id)
        createdAt = try container.decodeValue(forKeyPath: Keys.createdAt)
        urlItems = try container.decodeValue(forKeyPath: Keys.urlItems, decoder: JSONDecoder())
        defaultProfile = try container.decodeValue(forKeyPath: Keys.defaultProfile)
        followersCount = try container.decodeValue(forKeyPath: Keys.followersCount)
        url = container.decode(forKeyPath: Keys.url)
        description = try container.decodeValue(forKeyPath: Keys.description)
        
        if let bgColor: String = container.decode(forKeyPath: Keys.backgroundColor) {
            backgroundColor = UIColor.fromHex(hex: bgColor)
        } else {
            backgroundColor = nil
        }
    }
}

struct URLItem: Decodable {
    let displayURL: String
    let expandedURL: URL
    let url: URL
    let indices: [Int]
    
    enum CodingKeys: String, CodingKey {
        case displayURL = "display_url"
        case expandedURL = "expanded_url"
        case url
        case indices
    }
    
//    init(mapper: Mapper) throws {
//        displayUrl = try mapper.decodeValue(forKeyPath: "display_url")
//        expandedUrl = try mapper.decodeValue(forKeyPath: "expanded_url")
//        url = try mapper.decodeValue(forKeyPath: "url")
//        indices = try mapper.decodeValue(forKeyPath: "indices")
//    }
}
