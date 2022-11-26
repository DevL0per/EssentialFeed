//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by x.one on 26.11.22.
//

import CoreData

public class CoreDataFeedStore: FeedStore {
        
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
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
    
    private func perform(_ action: @escaping (NSManagedObjectContext)->Void) {
        let context = context
        context.perform { action(context) }
    }
    
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
    var local: LocalFeedImage {
        return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject, Identifiable {
    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = ManagedCache.fetchRequest()
        request.returnsObjectsAsFaults = true
        return try context.fetch(request).first as? ManagedCache
    }
    
    static func newUniqeInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
    }
    
    var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
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
