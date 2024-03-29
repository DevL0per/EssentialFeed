//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by x.one on 8.10.22.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    
    private let client: HTTPClient
    private let url: URL
    
    public typealias Result = FeedLoaderResult
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case .success(let response, let data):
                do {
                    let items = try FeedItemsMapper.map(response, data)
                    completion(.success(items.toModels()))
                } catch {
                    completion(.failure(error))
                }
            case .failure(_):
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description,
                              location: $0.location, url: $0.image) }
    }
}

private class FeedItemsMapper {
    
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
        
    static func map(_ response: HTTPURLResponse, _ data: Data) throws -> [RemoteFeedItem]  {
        guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return root.items
    }
}
