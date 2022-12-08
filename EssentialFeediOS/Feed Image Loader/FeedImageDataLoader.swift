//
//  FeedImageDataLoader.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import Foundation

public protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    func loadImageData(from url: URL, completion: @escaping (Result)->Void) -> FeedImageDataLoaderTask
}

public protocol FeedImageDataLoaderTask {
    func cancel()
}

