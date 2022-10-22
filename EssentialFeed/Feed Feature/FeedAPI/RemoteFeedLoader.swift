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
                completion(FeedItemsMapper.map(response, data))
            case .failure(_):
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}

private class FeedItemsMapper {
    
    static func map(_ response: HTTPURLResponse, _ data: Data) -> RemoteFeedLoader.Result  {
        guard response.statusCode == 200 else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return .success(root.items.map { $0.item })
        } catch {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
    }
}

private struct Root: Decodable {
    let items: [Item]
}

private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
        FeedItem(id: id,
                 description: description,
                 location: location,
                 imageURL: image)
    }
}

