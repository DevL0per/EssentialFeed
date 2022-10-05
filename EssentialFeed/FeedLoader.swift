//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by x.one on 5.10.22.
//

import Foundation

enum Result {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping () -> Void)
}
