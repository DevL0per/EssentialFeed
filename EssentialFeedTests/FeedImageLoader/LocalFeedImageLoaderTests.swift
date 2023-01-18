//
//  LocalFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 17.01.23.
//

import XCTest
import EssentialFeed

final class LocalFeedImageLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_loadImageData_retrievesDataForURL() {
        let (sut, store) = makeSUT()
        let url = URL(string: "anyURL.com")!
        
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve(dataFor: url)])
    }
    
    func test_loadImageData_deliversErrorOnStorageError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        expect(sut, toCompleteWith: .failure(error), when: {
            store.completeRetrival(with: error)
        })
    }
    
    func test_loadImageData_deliversNotFoundErrorOnEmptyStorage() {
        let (sut, store) = makeSUT()
        expect(sut, toCompleteWith: .failure(LocalFeedImageDataLoader.LoadError.notFound), when: {
            store.completeRetrival(with: nil)
        })
    }
    
    func test_loadImageData_deliversStoradeDataOnFoundData() {
        let (sut, store) = makeSUT()
        let nonEmptyData = "Non Empty".data(using: .utf8)!
        
        expect(sut, toCompleteWith: .success(nonEmptyData), when: {
            store.completeRetrival(with: nonEmptyData)
        })
    }
    
    func test_loadImageData_doesNotDeliverDataNorErrorAfterTaskHasBeenCanceled() {
        let (sut, store) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        let nonEmptyData = "Non Empty".data(using: .utf8)!

        var capturedResults: [Result<Data, Error>] = []
        let task = sut.loadImageData(from: url) { result in
            capturedResults.append(result)
        }
        task.cancel()
        
        store.completeRetrival(with: anyNSError())
        store.completeRetrival(with: nonEmptyData)
        store.completeRetrival(with: nil)
        
        XCTAssertEqual(capturedResults.count, 0)
    }
    
    func test_saveImageDataForURL_requestsImageDataInsertionForURL() {
        let (sut, store) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        let imageData = "Non Empty".data(using: .utf8)!
        
        sut.save(imageData, for: url)
        XCTAssertEqual(store.receivedMessages, [.insert(data: imageData, for: url)])
    }
    
    private func expect(_ sut: LocalFeedImageDataLoader, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
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
                         line: UInt = #line) -> (LocalFeedImageDataLoader, FeedImageStoreSPY) {
        let store = FeedImageStoreSPY()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
}

private class FeedImageStoreSPY: FeedImageStore {
    
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(data: Data, for: URL)
    }
    var receivedMessages = [Message]()
    var retrivalCompletions = [(RetrivalResult)->Void]()
    
    func insert(data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        receivedMessages.append(.insert(data: data, for: url))
    }
    
    func retrieve(dataForURL url: URL, completion: @escaping (RetrivalResult)->Void) {
        receivedMessages.append(.retrieve(dataFor: url))
        retrivalCompletions.append(completion)
    }
    
    func completeRetrival(with data: Data?, at index: Int = 0) {
        retrivalCompletions[index](.success(data))
    }
    
    func completeRetrival(with error: Error, at index: Int = 0) {
        retrivalCompletions[index](.failure(error))
    }
    
}
