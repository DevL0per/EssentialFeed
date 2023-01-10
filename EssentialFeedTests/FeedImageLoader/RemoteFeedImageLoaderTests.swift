//
//  RemoteFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 10.01.23.
//

import XCTest
import EssentialFeed

final class RemoteFeedImageDataLoader {
    
    enum Error: Swift.Error {
        case invalidData
    }
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result)->Void) {
        client.get(from: url, completion: { result in
            switch result {
            case let .success(response, data):
                guard response.statusCode == 200, !data.isEmpty else {
                    completion(.failure(Error.invalidData))
                    return
                }
            case .failure(let error):
                completion(.failure(error))
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
        let error = anyNSError()
        expect(sut, toCompleteWith: .failure(error), when: {
            client.complete(with: error)
        })
    }
    
    func test_loadImageData_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { (index, code) in
            expect(sut, toCompleteWith: .failure(RemoteFeedImageDataLoader.Error.invalidData), when: {
                client.complete(withStatusCode: code, data: Data(), index: index)
            })
        }
    }
    
    func test_loadImageData_deliversInvalidDataErrorOnEmptyData() {
        let (sut, client) = makeSUT()
        let emptyData = Data()
        
        expect(sut, toCompleteWith: .failure(RemoteFeedImageDataLoader.Error.invalidData), when: {
            client.complete(withStatusCode: 200, data: emptyData)
        })
    }
    
    private func expect(_ sut: RemoteFeedImageDataLoader, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: "https://a-given-url.com")!
        let exp = expectation(description: "Wait for load completion")
        
        sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (RemoteFeedImageDataLoader, HTTPClientSPY) {
        let client = HTTPClientSPY()
        let sut = RemoteFeedImageDataLoader(client: client)
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
        
        func complete(withStatusCode statusCode: Int, data: Data, index: Int = 0) {
            let message = messages[index]
            let httpResponse = HTTPURLResponse(url: message.url,
                                               statusCode: statusCode,
                                               httpVersion: nil,
                                               headerFields: nil)!
            messages[index].completion(.success(httpResponse, data))
        }
    }

}
