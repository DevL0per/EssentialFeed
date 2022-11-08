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
        let exp = expectation(description: "waiting for load completion")
        
        var receivedErrors = [NSError]()
        sut.load { receivedResult in
            switch receivedResult {
            case .success:
                XCTFail("expected error case")
            case .failure(let error):
                receivedErrors.append(error as NSError)
            }
            exp.fulfill()
        }
        store.completeRetrival(with: error)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedErrors, [error])
    }
    
    func test_load_deliversNoFeedItemsOnEmptyCache() {
        let (sut, store) = makeSUT()
        let exp = expectation(description: "waiting for load completion")

        var receivedItems = [FeedImage]()
        sut.load { result in
            switch result {
            case let .success(items):
                receivedItems = items
            case .failure:
                XCTFail("expected succes case, got failure insted")
            }
            exp.fulfill()
        }
        store.completeRetrival()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedItems, [])
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
