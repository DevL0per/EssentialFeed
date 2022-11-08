//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by x.one on 3.11.22.
//

import Foundation

public enum RetriveCachedFeedResult {
    case empty
    case failure(Error)
    case found(feed: [LocalFeedImage], timestamp: Date)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?)->Void
    typealias InsertionCompletion = (Error?)->Void
    typealias RetrivalCompletion = (RetriveCachedFeedResult)->Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrivalCompletion)
}
