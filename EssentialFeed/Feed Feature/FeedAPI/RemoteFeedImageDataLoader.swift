//
//  RemoteFeedImageDataLoader.swift
//  EssentialFeed
//
//  Created by x.one on 16.01.23.
//

import Foundation

public final class RemoteFeedImageDataLoader: FeedImageDataLoader {
    
    public enum Error: Swift.Error {
        case invalidData
    }
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    private class HTTPClientTaskWrapper: FeedImageDataLoaderTask {
        
        var wrapped: HTTPClientTask?
        var completion: ((FeedImageDataLoader.Result)->Void)?
        
        init(completion: (@escaping (FeedImageDataLoader.Result) -> Void)) {
            self.completion = completion
        }
        
        func cancel() {
            wrapped?.cancel()
            completion = nil
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
    }
    
    @discardableResult
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result)->Void) ->  FeedImageDataLoaderTask {
        let task = HTTPClientTaskWrapper(completion: completion)
        task.wrapped = client.get(from: url, completion: { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case let .success(response, data):
                guard response.statusCode == 200, !data.isEmpty else {
                    task.complete(with: .failure(Error.invalidData))
                    return
                }
            case .failure(let error):
                task.complete(with: .failure(error))
            }
        })
        return task
    }
    
}
