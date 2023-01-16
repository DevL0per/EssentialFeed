//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by x.one on 18.10.22.
//

import Foundation

public protocol HTTPClientTask {
    func cancel()
}

public typealias HTTPClientResult = Result<(HTTPURLResponse, Data), Error>

public protocol HTTPClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads
    @discardableResult
    func get(from url: URL, completion: @escaping (HTTPClientResult)->Void) -> HTTPClientTask
}
