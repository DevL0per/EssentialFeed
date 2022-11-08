//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 8.11.22.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotRetrieveFeedUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_callRetriveCommand() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrivalError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        expect(sut, toCompleteWithResult: .failure(error)) {
            store.completeRetrival(with: error)
        }
    }
    
    func test_load_deliversNoFeedItemsOnEmptyCache() {
        let (sut, store) = makeSUT()
        expect(sut, toCompleteWithResult: .success([])) {
            store.completeRetrival()
        }
    }
    
    func test_load_deliversCachedItemsOnLessThanSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = [uniqueItem, uniqueItem]
        let localItems = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        
        let lessThanSevenDaysOldTimestamp = Calendar(identifier: .gregorian).date(byAdding: .day, value: -7, to: Date())! + 1
         
        expect(sut, toCompleteWithResult: .success(feed)) {
            store.completeRetrival(with: localItems, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWithResult expectedResult: FeedLoaderResult,
                        on action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "waiting for load completion")

        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
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
    
    private var uniqueItem: FeedImage {
        let url = URL(string: "http://anyURL.com")!
        return FeedImage(id: UUID(), description: "any", location: "any", url: url)
    }

}
