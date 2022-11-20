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
        do {
            let encoder = JSONEncoder()
            let codableFeedImages = items.map(CodableFeedImage.init)
            let encoded = try encoder.encode(Cache(feed: codableFeedImages, timestamp: timestamp))
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        do {
            let decoded = try decoder.decode(Cache.self, from: data)
            let feed = decoded.feed.map { $0.local }
            completion(.found(feed: feed, timestamp: decoded.timestamp))
        } catch {
            completion(.failure(error))
        }
        
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
    
    func test_retrive_deliversFoundValuesOnNonEmptyCache() {
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
    
    func test_retrieve_deliversFailureOnRetrivalError() {
        let storeURL = testStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnRetrivalError() {
        let storeURL = testStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_insert_overridesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let oldFeed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let newFeed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        let firstInsertionError = insert((oldFeed, timestamp), to: sut)
        XCTAssertNil(firstInsertionError)
        
        let latestInsertionError = insert((newFeed, timestamp), to: sut)
        XCTAssertNil(latestInsertionError)
        
        expect(sut, toRetrieve: .found(feed: newFeed, timestamp: timestamp))
    }
    
    func test_insert_deliversAnErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid:://store-url")!
        let sut = makeSUT(storeURL: invalidURL)
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        let receivedError = insert((feed, timestamp), to: sut)
        
        XCTAssertNotNil(receivedError)
    }
    
    private func setupAnEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testStoreURL())
    }
    
    private func testStoreURL() -> URL {
        FileManager.default.urls(for: .documentDirectory,
        in: .userDomainMask).first!.appendingPathComponent("CodableFeedStoreTests.store")
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
        let expectation = expectation(description: "wait for cache retrieval")
        
        var receivedError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            expectation.fulfill()
            receivedError = insertionError
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedError
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
            case (.failure, .failure):
                break
            default:
                XCTFail("Expected \(expectedResult) result, got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
}
