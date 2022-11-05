//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by x.one on 5.10.22.
//

import Foundation

public enum FeedLoaderResult {
    case success([FeedImage])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (FeedLoaderResult) -> Void)
}
