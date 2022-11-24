//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by x.one on 24.11.22.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
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
    
}
