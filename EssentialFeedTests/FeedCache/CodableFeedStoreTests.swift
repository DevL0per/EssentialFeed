//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 20.11.22.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    typealias RetrivalCompletion = (RetriveCachedFeedResult)->Void
    typealias InsertionCompletion = (Error?)->Void
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory,
                           in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    private struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let url: URL
    }
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder = JSONEncoder()
        let codableFeedImages = items.map { toCodableFeedImage($0) }
        let encoded = try! encoder.encode(Cache(feed: codableFeedImages, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        let decoded = try! decoder.decode(Cache.self, from: data)
        
        let feed = decoded.feed.map { toLocalFeedImage($0) }
        completion(.found(feed: feed, timestamp: decoded.timestamp))
    }
    
    private func toCodableFeedImage(_ local: LocalFeedImage) -> CodableFeedImage {
        CodableFeedImage(id: local.id, description: local.description, location: local.location, url: local.url)
    }
    
    private func toLocalFeedImage(_ codable: CodableFeedImage) -> LocalFeedImage {
        LocalFeedImage(id: codable.id, description: codable.description, location: codable.location, url: codable.url)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                       in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                       in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrieve_deliversEmptyCacheOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "wait for cache retrieval")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retriveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "wait for cache retrieval")
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        sut.insert(feed, timestamp: timestamp) { insertionError in
            sut.retrieve { retrivalResult in
                switch retrivalResult {
                case .found(let retrievedFeed, let retrievedTimestamp):
                    XCTAssertEqual(retrievedFeed, feed)
                    XCTAssertEqual(retrievedTimestamp, timestamp)
                default:
                    XCTFail("Expected fount result with \(feed), got \(retrivalResult) instead")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}
