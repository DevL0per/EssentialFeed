//
//  CoreDataFeedStore+FeedImageDataLoader.swift
//  EssentialFeed
//
//  Created by x.one on 19.01.23.
//

import Foundation

extension CoreDataFeedStore: FeedImageStore {
    
    public func insert(data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        perform { context in
            guard let managedFeedImage = try? ManagedFeedImage.first(with: url, in: context) else { return }
            managedFeedImage.data = data
            
            try? context.save()
        }
    }
    
    public func retrieve(dataForURL url: URL, completion: @escaping (RetrivalResult) -> Void) {
        perform { context in
            completion(Result {
                try ManagedFeedImage.first(with: url, in: context)?.data
            })
        }
    }
    
}
