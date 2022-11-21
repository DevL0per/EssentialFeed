//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 20.11.22.
//

import XCTest
import EssentialFeed

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
    
    func test_delete_doesNothingOnEmptyCache() {
        let sut = makeSUT()
        
        let receivedError = delete(from: sut)
        XCTAssertNil(receivedError)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deletesDataOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to: sut)
        XCTAssertNil(insertionError, "expected successful insertion")
        delete(from: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversAnErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let receivedError = delete(from: sut)
        XCTAssertNotNil(receivedError)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        let today = Date()
        var completedOperationsInOrder: [XCTestExpectation] = []
        let item = mapFeedItemToLocalFeedImage(uniqueItem)
        
        let op1 = expectation(description: "Operation 1")
        sut.insert([item], timestamp: today) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed() { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert([item], timestamp: today) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3])
        
    }
    
    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
    private func delete(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for cache deletion")
        
        var receivedError: Error?
        sut.deleteCachedFeed { error in
            receivedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let expectation = expectation(description: "wait for cache retrieval")
        
        var receivedError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            expectation.fulfill()
            receivedError = insertionError
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedError
    }
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetriveCachedFeedResult,
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
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
}
