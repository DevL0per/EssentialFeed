//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by x.one on 18.10.22.
//

import Foundation

public enum HTTPClientResult {
    case success(HTTPURLResponse, Data)
    case failure(Error)
}

public protocol HTTPClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads
    func get(from url: URL, completion: @escaping (HTTPClientResult)->Void)
}
