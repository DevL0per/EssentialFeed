//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by x.one on 26.11.22.
//

import Foundation
import CoreData

class CoreDataFeedStore: FeedStore {
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
    func insert(_ items: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        completion(.empty)
    }
    
}

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
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
    @NSManaged var id: UUID?
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL?
    @NSManaged var cache: ManagedCache?
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject, Identifiable {
    @NSManaged public var timestamp: Date?
    @NSManaged public var feed: NSSet?
}
