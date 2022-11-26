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
        
    }
    
    public func insert(_ items: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = context
        context.performAndWait {
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
        let context = context
        context.perform {
            let fetchRequest = ManagedCache.fetchRequest()
            fetchRequest.returnsObjectsAsFaults = true
            do {
                let fetchResult = try context.fetch(fetchRequest)
                guard let feedCache = fetchResult.first as? ManagedCache else {
                    completion(.empty)
                    return
                }
                guard let feedImages = feedCache.feed.array as? [ManagedFeedImage] else {
                    completion(.empty)
                    return
                }
                completion(.found(feed: feedImages.toLocalFeedImages(), timestamp: feedCache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        
        var loadError: Swift.Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }
        
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject, Identifiable {
    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = ManagedCache.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first as? ManagedCache
    }
    
    static func newUniqeInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
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

private extension Array where Element == ManagedFeedImage {
    func toLocalFeedImages() -> [EssentialFeed.LocalFeedImage] {
        map {
            return EssentialFeed.LocalFeedImage(id: $0.id,
                                                description: $0.imageDescription,
                                                location: $0.location,
                                                url: $0.url)
        }
    }
}
