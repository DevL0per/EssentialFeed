//
//  LocalFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 17.01.23.
//

import XCTest
import EssentialFeed

final class LocalFeedImageDataLoader: FeedImageDataLoader {
    
    private let store: FeedImageStore
    private class Task: FeedImageDataLoaderTask {
        var completion: ((FeedImageDataLoader.Result)->Void)?
        
        init(completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            completion = nil
        }
    }
    enum Error: Swift.Error {
        case notFound
    }
    
    init(store: FeedImageStore) {
        self.store = store
    }
    
    @discardableResult
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result)->Void) ->  FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        store.retrieve(dataForURL: url) { result in
            task.complete(with:
                result.mapError { $0 }
                      .flatMap { data in
                  guard let data = data else { return .failure(Error.notFound) }
                  return .success(data)
            })
        }
        return task
    }
    
}

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
        expect(sut, toCompleteWith: .failure(LocalFeedImageDataLoader.Error.notFound), when: {
            store.completeRetrival(with: nil)
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
                         line: UInt = #line) -> (LocalFeedImageDataLoader, FeedImageStore) {
        let store = FeedImageStore()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
}

class FeedImageStore {
    
    enum Message: Equatable {
        case retrieve(dataFor: URL)
    }
    
    typealias FeedImageStoreResult = Result<Data?, Error>
    
    var receivedMessages = [Message]()
    var retrivalCompletions = [(FeedImageStoreResult)->Void]()
    
    func retrieve(dataForURL url: URL, completion: @escaping (FeedImageStoreResult)->Void) {
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
