//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by x.one on 26.11.22.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject, Identifiable {
    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
}

extension ManagedCache {
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
