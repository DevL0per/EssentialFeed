//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by x.one on 8.11.22.
//

import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias DeletionCompletion = (Error?)->Void
    typealias InsertionCompletion = (Error?)->Void
    typealias RetrivalCompletion = (RetriveCachedFeedResult)->Void
    
    struct Insertion: Equatable {
        let items: [LocalFeedImage]
        let timestamp: Date
    }
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert(Insertion)
        case retrieve
    }
    var receivedMessages: [ReceivedMessage] = []
    
    private var retrivalCompletion = [RetrivalCompletion]()
    private var deletionCompletion = [DeletionCompletion]()
    private var insertionCompletion = [InsertionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteCacheFeed)
        deletionCompletion.append(completion)
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let insertion = Insertion(items: items, timestamp: timestamp)
        receivedMessages.append(.insert(insertion))
        insertionCompletion.append(completion)
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        retrivalCompletion.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetrival(with error: Error, at index: Int = 0) {
        retrivalCompletion[index](.failure(error))
    }
    
    func completeRetrival(at index: Int = 0) {
        retrivalCompletion[index](.empty)
    }
    
    func completeRetrival(with items: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrivalCompletion[index](.found(feed: items, timestamp: timestamp))
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
