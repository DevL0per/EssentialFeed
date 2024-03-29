//
//  RemoteFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 10.01.23.
//

import XCTest
import EssentialFeed

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
    
    func test_loadImageData_doesNotDeliverDataAfterInstanceHasBeenDeallocated() {
        let client = HTTPClientSPY()
        var sut: RemoteFeedImageDataLoader? = RemoteFeedImageDataLoader(client: client)
        let url = URL(string: "https://a-given-url.com")!
        let error = anyNSError()
        
        var capturedResults = [FeedImageDataLoader.Result]()
        sut?.loadImageData(from: url) { result in
            capturedResults.append(result)
        }
        sut = nil
        client.complete(with: error)
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    func test_cancelLoadImageDataURLTask_cancelesClientURLRequest() {
        let (sut, client) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        
        let task = sut.loadImageData(from: url) { _ in }
        XCTAssertTrue(client.canceledURLs.isEmpty)
        
        task.cancel()
        XCTAssertEqual(client.canceledURLs, [url])
    }
    
    func test_loadImageData_doesNotDeliverDataNorErrorAfterTaskHasBeenCanceled() {
        let (sut, client) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        let nonEmptyData = "Non Empty".data(using: .utf8)!

        var capturedResults: [Result<Data, Error>] = []
        let task = sut.loadImageData(from: url) { result in
            capturedResults.append(result)
        }
        task.cancel()
        
        client.complete(with: anyNSError())
        client.complete(withStatusCode: 200, data: nonEmptyData)
        client.complete(withStatusCode: 400, data: Data())
        
        XCTAssertEqual(capturedResults.count, 0)
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
        var canceledURLs = [URL]()
        
        private struct Task: HTTPClientTask {
            let onCancel: ()->Void
            
            func cancel() {
                onCancel()
            }
        }
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) -> EssentialFeed.HTTPClientTask {
            requestedURLs.append(url)
            messages.append((url, completion))
            
            let task = Task { [weak self] in
                self?.canceledURLs.append(url)
            }
            return task
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
            messages[index].completion(.success((httpResponse, data)))
        }
    }

}
