//
//  FeedImageDataStoreSpy.swift
//  EssentialFeedTests
//
//  Created by x.one on 18.01.23.
//

import EssentialFeed

class FeedImageStoreSPY: FeedImageStore {
    
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(data: Data, for: URL)
    }
    var receivedMessages = [Message]()
    var retrivalCompletions = [(RetrivalResult)->Void]()
    var insertionCompletions = [(InsertionResult)->Void]()
    
    func insert(data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        receivedMessages.append(.insert(data: data, for: url))
        insertionCompletions.append(completion)
    }
    
    func retrieve(dataForURL url: URL, completion: @escaping (RetrivalResult)->Void) {
        receivedMessages.append(.retrieve(dataFor: url))
        retrivalCompletions.append(completion)
    }
    
    func completeRetrival(with data: Data?, at index: Int = 0) {
        retrivalCompletions[index](.success(data))
    }
    
    func completeRetrival(with error: Error, at index: Int = 0) {
        retrivalCompletions[index](.failure(error))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }
    
}
