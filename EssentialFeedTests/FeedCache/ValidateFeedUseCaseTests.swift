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
        
        sut.validateCache() { _ in }
        store.completeRetrival(with: error)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeletesCachedItemsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache() { _ in }
        store.completeRetrivalWithAnEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteLessThanMaxAgeOldCache() {
        let today = Date()
        let (sut, store) = makeSUT(timestamp: { today })
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        
        let maxAgeOldTimestamp = today.minusFeedCacheMaxAge().adding(seconds: 1)
        
        sut.validateCache() { _ in }
        store.completeRetrival(with: localItems, timestamp: maxAgeOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_deletesMaxAgeOldCache() {
        let today = Date()
        let (sut, store) = makeSUT(timestamp: { today })
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        let maxAgeOldTimestamp = today.minusFeedCacheMaxAge()
        
        sut.validateCache() { _ in }
        store.completeRetrival(with: localItems, timestamp: maxAgeOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_deletesMoreThanMaxAgeOldCache() {
        let today = Date()
        let (sut, store) = makeSUT(timestamp: { today })
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        let maxAgeOldTimestamp = today.minusFeedCacheMaxAge().adding(seconds: -1)
        
        sut.validateCache() { _ in }
        store.completeRetrival(with: localItems, timestamp: maxAgeOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_failesOnDeletionErrorOfFailedRetrieval() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWithResult: .failure(deletionError)) {
            store.completeRetrival(with: anyNSError())
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_validate_succeedsOnEmptyCache() {
        let (sut, store) = makeSUT()
        expect(sut, toCompleteWithResult: .success(())) {
            store.completeRetrival(with: [], timestamp: Date())
        }
    }
    
    func test_validate_succeedsOnNonExpiredCache() {
        let (sut, store) = makeSUT()
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        expect(sut, toCompleteWithResult: .success(())) {
            store.completeRetrival(with: localItems, timestamp: Date())
        }
    }
    
    func test_validate_failsOnDeletionErrorOfExpiredCache() {
        let (sut, store) = makeSUT()
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        let deletionError = anyNSError()
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
        
        expect(sut, toCompleteWithResult: .failure(deletionError)) {
            store.completeRetrival(with: localItems, timestamp: expiredTimestamp)
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_validate_succeedsOnSuccessfullDeletion() {
        let (sut, store) = makeSUT()
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
        
        expect(sut, toCompleteWithResult: .success(())) {
            store.completeRetrival(with: localItems, timestamp: expiredTimestamp)
            store.completeDeletionSuccessfully()
        }
    }
    
    func test_load_doesNotDeleteInvalidCacheAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: { Date() })
        let today = Date()
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { mapFeedItemToLocalFeedImage($0) }
        
        let sevenDaysOldTimestamp = today.minusFeedCacheMaxAge().adding(seconds: -1)
        
        sut?.validateCache() { _ in }
        sut = nil
        store.completeRetrival(with: localItems, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWithResult expectedResult: LocalFeedLoader.ValidationResult,
                        on action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "waiting for load completion")

        sut.validateCache { result in
            switch (result, expectedResult) {
            case (.success, .success):
                break
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, file: file, line: line)
            default:
                XCTFail("expected \(expectedResult), got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)

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
