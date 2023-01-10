//
//  RemoteFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 10.01.23.
//

import XCTest
import EssentialFeed

final class RemoteFeedImageLoader {
    
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func loadImageData(from url: URL, completion: @escaping (Error)->Void) {
        client.get(from: url, completion: { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                completion(error)
            }
        })
    }
    
}

final class RemoteFeedImageLoaderTests: XCTestCase {

    func test_init_doesNotPerfrormAnyURLRequests() {
        let (_, client) = makeSUT()
        XCTAssertEqual(client.requestedURLs, [])
    }
    
    func test_loadImageData_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        let url = URL(string: "anyURL.com")!
        
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadImageData_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()
        let url = URL(string: "anyURL.com")!
        
        sut.loadImageData(from: url) { _ in }
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadImageData_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let url = URL(string: "anyURL.com")!
        let error = anyNSError()
        let exp = expectation(description: "wait for loadImageData completion")
        
        sut.loadImageData(from: url) { receivedError in
            XCTAssertEqual(receivedError as NSError, error)
            exp.fulfill()
        }
        client.complete(with: error)
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (RemoteFeedImageLoader, HTTPClientSPY) {
        let client = HTTPClientSPY()
        let sut = RemoteFeedImageLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private class HTTPClientSPY: HTTPClient {
        var requestedURLs = [URL]()
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            requestedURLs.append(url)
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
    }

}
