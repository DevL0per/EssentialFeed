//
//  ValidateFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 13.11.22.
//

import XCTest
import EssentialFeed

final class ValidateFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deletesCachedItemsOnRetrivalError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        sut.validateCache() {}
        store.completeRetrival(with: error)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeletesCachedItemsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache() {}
        store.completeRetrivalWithAnEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteLessThanMaxAgeOldCache() {
        let today = Date()
        let (sut, store) = makeSUT(timestamp: { today })
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        
        let maxAgeOldTimestamp = today.minusFeedCacheMaxAge().adding(seconds: 1)
        
        sut.validateCache() {}
        store.completeRetrival(with: localItems, timestamp: maxAgeOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_deletesMaxAgeOldCache() {
        let today = Date()
        let (sut, store) = makeSUT(timestamp: { today })
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        let maxAgeOldTimestamp = today.minusFeedCacheMaxAge()
        
        sut.validateCache() {}
        store.completeRetrival(with: localItems, timestamp: maxAgeOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_deletesMoreThanMaxAgeOldCache() {
        let today = Date()
        let (sut, store) = makeSUT(timestamp: { today })
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        let maxAgeOldTimestamp = today.minusFeedCacheMaxAge().adding(seconds: -1)
        
        sut.validateCache() {}
        store.completeRetrival(with: localItems, timestamp: maxAgeOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_load_doesNotDeleteInvalidCacheAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: { Date() })
        let today = Date()
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        let sevenDaysOldTimestamp = today.minusFeedCacheMaxAge().adding(seconds: -1)
        
        sut?.validateCache() {}
        sut = nil
        store.completeRetrival(with: localItems, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    private func makeSUT(timestamp: @escaping ()->(Date) = { Date() },
                         file: StaticString = #file,
                         line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
}
