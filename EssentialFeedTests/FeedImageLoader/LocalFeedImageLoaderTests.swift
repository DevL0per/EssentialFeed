//
//  LocalFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 17.01.23.
//

import XCTest
import EssentialFeed

final class LocalFeedImageDataLoader: FeedImageDataLoader {
    
    private let store: FeedImageStore
    private struct Task: FeedImageDataLoaderTask {
        func cancel() {}
    }
    
    init(store: FeedImageStore) {
        self.store = store
    }
    
    @discardableResult
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result)->Void) ->  FeedImageDataLoaderTask {
        store.retrieve(dataForURL: url)
        return Task()
    }
    
}

final class LocalFeedImageLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_loadImageData_retrievesDataForURL() {
        let (sut, store) = makeSUT()
        let url = URL(string: "anyURL.com")!
        
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve(dataFor: url)])
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

class FeedImageStore {
    
    enum Message: Equatable {
        case retrieve(dataFor: URL)
    }
    
    var receivedMessages = [Message]()
    
    func retrieve(dataForURL url: URL) {
        receivedMessages.append(.retrieve(dataFor: url))
    }
    
}
