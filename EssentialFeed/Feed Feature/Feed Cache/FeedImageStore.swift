//
//  FeedImageStore.swift
//  EssentialFeed
//
//  Created by x.one on 17.01.23.
//

import Foundation

public protocol FeedImageStore {
    typealias RetrivalResult = Result<Data?, Error>
    typealias InsertionResult = Result<Void, Error>

    func insert(data: Data, for url: URL, completion: @escaping (InsertionResult)->Void)
    func retrieve(dataForURL url: URL, completion: @escaping (RetrivalResult)->Void)
}
