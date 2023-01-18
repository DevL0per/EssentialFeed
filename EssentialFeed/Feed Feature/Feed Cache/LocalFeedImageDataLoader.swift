//
//  LocalFeedImageDataLoader.swift
//  EssentialFeedTests
//
//  Created by x.one on 17.01.23.
//

import Foundation

public final class LocalFeedImageDataLoader: FeedImageDataLoader {
    
    private let store: FeedImageStore
    private class Task: FeedImageDataLoaderTask {
        var completion: ((FeedImageDataLoader.Result)->Void)?
        
        init(completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            completion = nil
        }
    }
    public enum Error: Swift.Error {
        case notFound
    }
    
    public init(store: FeedImageStore) {
        self.store = store
    }
    
    public func save(_ data: Data, for url: URL) {
        store.insert(data: data, for: url)
    }
    
    @discardableResult
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result)->Void) ->  FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        store.retrieve(dataForURL: url) { result in
            task.complete(with: result
                .mapError { $0 }
                .flatMap { data in
                    data.map { .success($0) } ?? .failure(Error.notFound)
            })
        }
        return task
    }
    
}
