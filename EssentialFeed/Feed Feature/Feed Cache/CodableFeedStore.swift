//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by x.one on 20.11.22.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private let storeURL: URL
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        init(_ localFeedImage: LocalFeedImage) {
            id = localFeedImage.id
            description = localFeedImage.description
            location = localFeedImage.location
            url = localFeedImage.url
        }
        
        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    private let queue = DispatchQueue(label: "CodableFeedStoreQueue", qos: .userInitiated, attributes: .concurrent)
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = storeURL
        queue.async(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                let codableFeedImages = items.map(CodableFeedImage.init)
                let encoded = try encoder.encode(Cache(feed: codableFeedImages, timestamp: timestamp))
                try encoded.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        let storeURL = storeURL
        queue.async() {
            let decoder = JSONDecoder()
            guard let data = try? Data(contentsOf: storeURL) else {
                completion(.empty)
                return
            }
            do {
                let decoded = try decoder.decode(Cache.self, from: data)
                let feed = decoded.feed.map { $0.local }
                completion(.found(feed: feed, timestamp: decoded.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURL = storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(nil)
            }
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
