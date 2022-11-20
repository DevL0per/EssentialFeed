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
    
    private let storeURL: URL
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        init(_ localFeedImage: LocalFeedImage) {
            id = localFeedImage.id
            description = localFeedImage.description
            location = localFeedImage.location
            url = localFeedImage.url
        }
        
        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder = JSONEncoder()
        let codableFeedImages = items.map(CodableFeedImage.init)
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
        
        let feed = decoded.feed.map { $0.local }
        completion(.found(feed: feed, timestamp: decoded.timestamp))
    }
    
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        try? FileManager.default.removeItem(at: storeURL())
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try? FileManager.default.removeItem(at: storeURL())
    }
    
    func test_retrieve_deliversEmptyCacheOnEmptyCache() {
        let sut = makeSUT()
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
        let sut = makeSUT()
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
    
    private func storeURL() -> URL {
        FileManager.default.urls(for: .documentDirectory,
        in: .userDomainMask).first!.appendingPathComponent("CodableFeedStoreTests.store")
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let storeURL = storeURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
}
