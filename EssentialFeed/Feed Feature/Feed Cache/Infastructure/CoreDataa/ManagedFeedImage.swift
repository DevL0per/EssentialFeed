//
//  ManagedFeedImage.swift
//  EssentialFeed
//
//  Created by x.one on 26.11.22.
//

import CoreData

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var data: Data?
    @NSManaged var cache: ManagedCache
}

extension ManagedFeedImage {
    
    var local: LocalFeedImage {
        return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
    }
    
    static func first(with url: URL, in context: NSManagedObjectContext) throws -> ManagedFeedImage? {
        let fetchRequest = ManagedFeedImage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(ManagedFeedImage.url), url])
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchLimit = 1
        return try (context.fetch(fetchRequest).first as? ManagedFeedImage)
    }
    
}
