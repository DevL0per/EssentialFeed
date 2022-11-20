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
        setupAnEmptyStoreState()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyCacheOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retriveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    private func setupAnEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: storeURL())
    }
    
    private func storeURL() -> URL {
        FileManager.default.urls(for: .documentDirectory,
        in: .userDomainMask).first!.appendingPathComponent("CodableFeedStoreTests.store")
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
        let expectation = expectation(description: "wait for cache retrieval")
        
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetriveCachedFeedResult,
                        file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for cache retrieval")
        
        sut.retrieve { result in
            switch (result, expectedResult) {
            case (.empty, .empty):
                break
            case let (.found(retrievedFeed, retrievedTimestamp),
                      .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp)
            default:
                XCTFail("Expected \(expectedResult) result, got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let storeURL = storeURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
}
