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
    
    private var maxCacheAgeInDays: Int {
        7
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxDate = calendar.date(byAdding: .day, value: -maxCacheAgeInDays, to: self.timestamp()) else { return false }
        return timestamp > maxDate
    }

}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .found(_, timestamp) where !self.validate(timestamp):
                self.store.deleteCachedFeed(completion: {_ in})
            case .failure:
                self.store.deleteCachedFeed(completion: {_ in})
            default:
                break
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
        store.insert(items.toLocal(), timestamp: self.timestamp()) { [weak self] error in
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
            case let .found(feedItems, timestamp) where self.validate(timestamp):
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
