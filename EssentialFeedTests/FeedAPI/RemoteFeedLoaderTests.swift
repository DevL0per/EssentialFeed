//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 6.10.22.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestedURLs, [])
    }
    
    func test_load_requsetDataFromURL() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_requestDataFromURLOnes() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_requestDataFromURLTwice() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
                let json = createItemsJSON(items: [])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200ResponseHTTPResponseWithInvalideJSON() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)

        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
            let invalidData = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidData)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSON() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        expect(sut, toCompleteWith: .success([])) {
            let data = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: data)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let url = URL(string: "google.com//a-given")!
        let (sut, client) = makeSUT(url: url)
        
        let feedItem1 = createItem(id: UUID(),
                                   imageURL: URL(string: "http://a-url.com")!)
        let feedItem2 = createItem(id: UUID(),
                                   description: "description",
                                   location: "location",
                                   imageURL: URL(string: "http://a-url.com")!)
        expect(sut, toCompleteWith: .success([feedItem1.feedItem, feedItem2.feedItem])) {
            let json = createItemsJSON(items: [feedItem1.jsonValues, feedItem2.jsonValues])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let url = URL(string: "google.com//a-given")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var captureResults: [RemoteFeedLoader.Result] = []
        sut?.load(completion: { result in
            captureResults.append(result)
        })
        sut = nil
        client.complete(withStatusCode: 200)
        
        XCTAssertTrue(captureResults.isEmpty)
    }
    
    private func createItemsJSON(items: [[String: Any]]) -> Data {
        let json = [
            "items": items
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func createItem(id: UUID, description: String? = nil,
                            location: String? = nil, imageURL: URL) -> (feedItem: FeedImage, jsonValues: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)
        let json = [
            "id": item.id.uuidString,
            "image": item.url.absoluteString,
            "description": item.description,
            "location": item.location
        ].reduce(into: [String: Any]()) { partialResult, dict in
            if dict.value != nil {
                partialResult[dict.key] = dict.value
            }
        }
        return (item, json)
    }
    
    private func makeSUT(url: URL = URL(string: "google.com//a-given")!,
                         file: StaticString = #file, line: UInt = #line)
    -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
    
        addTeardownBlock { [weak sut, weak client] in
            XCTAssertNil(sut, file: file, line: line)
            XCTAssertNil(client, file: file, line: line)
        }
        
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith result: RemoteFeedLoader.Result,
                        when action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for load complection")
        sut.load { feedLoaderResult in
            switch (feedLoaderResult, result) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(result) got \(feedLoaderResult)")
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {
                
        private struct Task: HTTPClientTask {
            func cancel() {}
        }
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        var messages = [(url: URL, completion: (HTTPClientResult)->Void)]()
    
        func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) -> EssentialFeed.HTTPClientTask {
            messages.append((url, completion))
            return Task()
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code,
                                           httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(response, data))
        }
        
    }

}
