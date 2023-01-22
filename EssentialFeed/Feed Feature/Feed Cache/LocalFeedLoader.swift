//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by x.one on 3.11.22.
//

import Foundation

public class LocalFeedLoader {
    let store: FeedStore
    
    private let currentDate: ()->Date
    
    public init(store: FeedStore, timestamp: @escaping ()->Date) {
        self.store = store
        self.currentDate = timestamp
    }

}

extension LocalFeedLoader {
    
    public typealias ValidationResult = Result<Void, Error>
    
    public func validateCache(completion: @escaping (ValidationResult)->Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCachedFeed(completion: { error in
                    if let error = error { completion(.failure(error))}
                    else { completion(.success(())) }
                })
            case .failure:
                self.store.deleteCachedFeed { error in
                    if let error = error { completion(.failure(error))}
                    else { completion(.success(())) }
                }
            default:
                completion(.success(()))
            }
        }
    }
}

extension LocalFeedLoader {
    public func save(_ items: [FeedImage], completion: @escaping (Error?)->()) {
        store.deleteCachedFeed() { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(error)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedImage], with completion: @escaping (Error?)->Void) {
        store.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard let _ = self else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public func load(completion: @escaping (FeedLoaderResult)->Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .found(feedItems, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(feedItems.toModel()))
            case let .failure(error):
                completion(.failure(error))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModel()->[FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == FeedImage {
    func toLocal()->[LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
