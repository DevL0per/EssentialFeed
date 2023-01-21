//
//  CoreDataFeedStore+FeedStore.swift
//  EssentialFeed
//
//  Created by x.one on 21.01.23.
//

import CoreData

extension CoreDataFeedStore: FeedStore {
        
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            do {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
                completion(nil)
            } catch {
                completion(error)
            }
            
        }
    }
    
    public func insert(_ items: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqeInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.feed = NSOrderedSet(array: items.toManagedObjects(context: context))
                
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
        
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        perform { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}

private extension Array where Element == EssentialFeed.LocalFeedImage {
    func toManagedObjects(context: NSManagedObjectContext) -> [ManagedFeedImage] {
        map {
            let managedFeedImage = ManagedFeedImage(context: context)
            managedFeedImage.id = $0.id
            managedFeedImage.imageDescription = $0.description
            managedFeedImage.location = $0.location
            managedFeedImage.url = $0.url
            return managedFeedImage
        }
    }
}
