//
//  FeedImageStore.swift
//  EssentialFeed
//
//  Created by x.one on 17.01.23.
//

import Foundation

public protocol FeedImageStore {
    typealias FeedImageStoreResult = Result<Data?, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (FeedImageStoreResult)->Void)
}
