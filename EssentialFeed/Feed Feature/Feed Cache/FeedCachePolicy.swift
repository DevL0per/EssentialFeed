//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by x.one on 15.11.22.
//

import Foundation

final class FeedCachePolicy {
    
    private init() {}
    
    static private var maxCacheAgeInDays: Int {
        7
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxDate = calendar.date(byAdding: .day, value: -maxCacheAgeInDays, to: date) else { return false }
        return timestamp > maxDate
    }
}
