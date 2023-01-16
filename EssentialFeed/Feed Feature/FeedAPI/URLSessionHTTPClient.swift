//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by x.one on 18.10.22.
//

import Foundation

final public class URLSessionHTTPClient: HTTPClient {
    
    private let urlSession: URLSession
     
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionDataTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    struct UnexpectedValuesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask {
        let task = urlSession.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((response, data)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}
