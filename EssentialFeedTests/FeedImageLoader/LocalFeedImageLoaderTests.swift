//
//  LocalFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 17.01.23.
//

import XCTest
import EssentialFeed

final class LocalFeedImageDataLoader {
    
    init(store: Any) {
        
    }
    
}

final class LocalFeedImageLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (LocalFeedImageDataLoader, FeedImageStore) {
        let store = FeedImageStore()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
}

private class FeedImageStore {
    
    var receivedMessages = [String]()
    
}
