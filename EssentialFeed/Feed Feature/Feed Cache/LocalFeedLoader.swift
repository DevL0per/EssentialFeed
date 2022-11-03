//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by x.one on 3.11.22.
//

import Foundation

public class LocalFeedLoader {
    let store: FeedStore
    let timestamp: ()->(Date)
    
    public init(store: FeedStore, timestamp: @escaping ()->Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Error?)->()) {
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
