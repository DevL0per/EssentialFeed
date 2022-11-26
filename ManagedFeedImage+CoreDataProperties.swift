//
//  ManagedFeedImage+CoreDataProperties.swift
//  EssentialFeed
//
//  Created by x.one on 26.11.22.
//
//

import Foundation
import CoreData


extension ManagedFeedImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedFeedImage> {
        return NSFetchRequest<ManagedFeedImage>(entityName: "ManagedFeedImage")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var imageDescription: String?
    @NSManaged public var location: String?
    @NSManaged public var url: URL?
    @NSManaged public var cache: ManagedCache?

}

extension ManagedFeedImage : Identifiable {

}
