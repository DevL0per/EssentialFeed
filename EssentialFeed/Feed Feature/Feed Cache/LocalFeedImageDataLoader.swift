//
//  LocalFeedImageDataLoader.swift
//  EssentialFeedTests
//
//  Created by x.one on 17.01.23.
//

import Foundation

public final class LocalFeedImageDataLoader {
    private let store: FeedImageStore
    
    public init(store: FeedImageStore) {
        self.store = store
    }
    
}

extension LocalFeedImageDataLoader {
    
    public typealias SaveResult = Result<Void, Error>
    
    public func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        store.insert(data: data, for: url) { [weak self] result in
            guard let _ = self else { return }
            completion(result)
        }
    }
    
}

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    
    public enum LoadError: Swift.Error {
        case notFound
    }
    
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
    
    @discardableResult
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result)->Void) ->  FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        store.retrieve(dataForURL: url) { result in
            task.complete(with: result
                .mapError { $0 }
                .flatMap { data in
                    data.map { .success($0) } ?? .failure(LoadError.notFound)
            })
        }
        return task
    }
    
}
