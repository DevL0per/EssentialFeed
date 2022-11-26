//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by x.one on 24.11.22.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversEmptyCacheOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatRetriveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp), file: file, line: line)
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp), file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFailureOnRetrivalError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnRetrivalError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
        expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let oldFeed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let newFeed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        let firstInsertionError = insert((oldFeed, timestamp), to: sut)
        XCTAssertNil(firstInsertionError, file: file, line: line)
        
        let latestInsertionError = insert((newFeed, timestamp), to: sut)
        XCTAssertNil(latestInsertionError, file: file, line: line)
        
        expect(sut, toRetrieve: .found(feed: newFeed, timestamp: timestamp), file: file, line: line)
    }
    
    func assertThatInsertDeliversAnErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        let receivedError = insert((feed, timestamp), to: sut)
        
        XCTAssertNotNil(receivedError, file: file, line: line)
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatDeleteDoesNothingOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let receivedError = delete(from: sut)
        XCTAssertNil(receivedError)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatDeleteDeletesDataOnNonEmptyCache(sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = [uniqueItem, uniqueItem].map { mapFeedItemToLocalFeedImage($0) }
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to: sut)
        XCTAssertNil(insertionError, "expected successful insertion")
        delete(from: sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatDeleteDeliversAnErrorOnDeletionError(sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let receivedError = delete(from: sut)
        XCTAssertNotNil(receivedError, file: file, line: line)
    }
    
    func assertThatStoreSideEffectsRunSerially(sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
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
        
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], file: file, line: line)
    }
    
    @discardableResult
    func delete(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for cache deletion")
        
        var receivedError: Error?
        sut.deleteCachedFeed { error in
            receivedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        return receivedError
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let expectation = expectation(description: "wait for cache retrieval")
        
        var receivedError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            expectation.fulfill()
            receivedError = insertionError
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedError
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetriveCachedFeedResult,
                        file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for cache retrieval")
        
        sut.retrieve { result in
            switch (result, expectedResult) {
            case (.empty, .empty):
                break
            case let (.found(retrievedFeed, retrievedTimestamp),
                      .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
            case (.failure, .failure):
                break
            default:
                XCTFail("Expected \(expectedResult) result, got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
}
