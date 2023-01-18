//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 18.01.23.
//

import XCTest
import EssentialFeed

extension CoreDataFeedStore: FeedImageStore {
    
    public func insert(data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        
    }
    
    public func retrieve(dataForURL url: URL, completion: @escaping (RetrivalResult) -> Void) {
        completion(.success(.none))
    }
    
}

final class CoreDataFeedImageDataStoreTests: XCTestCase {

    func test_retriveImageData_deliversNotFoundOnEmptyStorage() {
        let sut = makeSUT()
        let url = URL(string: "anyURL")!
        expect(sut, toCompleteRetrivalWith: notFound(), for: url)
    }
    
    func test_retriveImageData_deliversNotFoundOnNonEmptyStorage() {
        let sut = makeSUT()
        let testData = "TestData".data(using: .utf8)!
        let url = URL(string: "anyURL")!
        
        sut.insert(data: testData, for: url) { _ in }
        
        let nonMachingURL = URL(string: "anyURL0")!
        expect(sut, toCompleteRetrivalWith: notFound(), for: nonMachingURL)
    }
    
    private func notFound() -> FeedImageStore.RetrivalResult {
        return .success(.none)
    }
    
    private func expect(_ sut: CoreDataFeedStore, toCompleteRetrivalWith expectedResult: FeedImageStore.RetrivalResult, for url: URL,file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for retrive completion")
        
        sut.retrieve(dataForURL: url) { receivedResult in
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
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
}
