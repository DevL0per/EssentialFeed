//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 1.11.22.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    let store: FeedStore
    let timestamp: ()->(Date)
    
    init(store: FeedStore, timestamp: @escaping ()->(Date)) {
        self.store = store
        self.timestamp = timestamp
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed() { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.timestamp())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?)->Void
    
    struct Insertion: Equatable {
        let items: [FeedItem]
        let timestamp: Date
    }
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert(Insertion)
    }
    var receivedMessages: [ReceivedMessage] = []
    
    private var deletionCompletion = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteCacheFeed)
        deletionCompletion.append(completion)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        let insertion = Insertion(items: items, timestamp: timestamp)
        receivedMessages.append(.insert(insertion))
    }
    
    func compleDeletion(with error: Error, at index: Int = 0) {
        deletionCompletion[index](error)
    }
    
    func compleDeletionSuccessfully(at index: Int = 0) {
        deletionCompletion[index](nil)
    }
    
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem, uniqueItem]
        sut.save(items)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem, uniqueItem]
        sut.save(items)
        
        let deletionError = anyNSError()
        store.compleDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSucessDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: {timestamp})
        let items = [uniqueItem, uniqueItem]
        sut.save(items)
        
        store.compleDeletionSuccessfully()
        
        let insertion = FeedStore.Insertion(items: items, timestamp: timestamp)
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(insertion)])
    }
    
    private func makeSUT(timestamp: @escaping ()->(Date) = { Date() },
                         file: StaticString = #file,
                         line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private var uniqueItem: FeedItem {
        let url = URL(string: "http://anyURL.com")!
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: url)
    }
    
}
