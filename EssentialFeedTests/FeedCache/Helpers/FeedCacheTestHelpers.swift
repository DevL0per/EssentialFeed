//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by x.one on 13.11.22.
//

import XCTest
import EssentialFeed

extension Date {
    
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
    
}

var uniqueItem: FeedImage {
    let url = URL(string: "http://anyURL.com")!
    return FeedImage(id: UUID(), description: "any", location: "any", url: url)
}

