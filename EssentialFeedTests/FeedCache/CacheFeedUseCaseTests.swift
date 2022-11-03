//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 1.11.22.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    let store: FeedStoreSpy
    let timestamp: ()->(Date)
    
    init(store: FeedStoreSpy, timestamp: @escaping ()->Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?)->()) {
        store.deleteCachedFeed() { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(error)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?)->Void) {
        store.insert(items, timestamp: self.timestamp()) { [weak self] error in
            guard let _ = self else { return }
            completion(error)
        }
    }
}

class FeedStoreSpy: FeedStore {
    typealias DeletionCompletion = (Error?)->Void
    typealias InsertionCompletion = (Error?)->Void
    
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
    private var insertionCompletion = [InsertionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteCacheFeed)
        deletionCompletion.append(completion)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        let insertion = Insertion(items: items, timestamp: timestamp)
        receivedMessages.append(.insert(insertion))
        insertionCompletion.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletion[index](error)
    }
    
    func compleDeletionSuccessfully(at index: Int = 0) {
        deletionCompletion[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletion[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletion[index](nil)
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?)->Void
    typealias InsertionCompletion = (Error?)->Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem, uniqueItem]
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem, uniqueItem]
        sut.save(items) { _ in }
        
        let deletionError = anyNSError()
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSucessDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: {timestamp})
        let items = [uniqueItem, uniqueItem]
        sut.save(items) { _ in }
        
        store.compleDeletionSuccessfully()
        
        let insertion = FeedStoreSpy.Insertion(items: items, timestamp: timestamp)
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(insertion)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWithAnError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithAnError: insertionError) {
            store.compleDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem, uniqueItem]
        let exp = expectation(description: "wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        store.compleDeletionSuccessfully()
        store.completeInsertionSuccessfully()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(receivedError)
    }
    
    func test_save_doesNotDeliversDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        let deletionError = anyNSError()
        let items = [uniqueItem, uniqueItem]
        
        var receivedResults = [Error?]()
        sut?.save(items, completion: { error in
            receivedResults.append(error)
        })
        sut = nil
        store.completeDeletion(with: deletionError)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliversInsertionErrorAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        let insertionError = anyNSError()
        let items = [uniqueItem, uniqueItem]
        
        var receivedResults = [Error?]()
        sut?.save(items, completion: { error in
            receivedResults.append(error)
        })
        store.compleDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: insertionError)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithAnError error: NSError, when action: @escaping ()->Void) {
        let exp = expectation(description: "wait for save completion")
        
        var receivedError: Error?
        sut.save([uniqueItem]) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, error)
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
    
    private var uniqueItem: FeedItem {
        let url = URL(string: "http://anyURL.com")!
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: url)
    }
    
}
