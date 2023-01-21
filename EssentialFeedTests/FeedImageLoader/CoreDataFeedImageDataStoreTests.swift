//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 18.01.23.
//

import XCTest
import EssentialFeed

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
    
    func test_retriveImageData_deliversImageDataFoundOnWhenThereIsAStoredImageDataMatchingURL() {
        let sut = makeSUT()
        let testData = "TestData".data(using: .utf8)!
        let url = URL(string: "anyURL")!
        
        insert(testData, for: url, into: sut)
        
        expect(sut, toCompleteRetrivalWith: .success(testData), for: url)
    }
    
    private func notFound() -> FeedImageStore.RetrivalResult {
        return .success(.none)
    }
    
    private func expect(_ sut: CoreDataFeedStore, toCompleteRetrivalWith expectedResult: FeedImageStore.RetrivalResult, for url: URL, file: StaticString = #file, line: UInt = #line) {
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
    
    private func insert(_ data: Data, for url: URL, into sut: CoreDataFeedStore, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for insertion")
        let image = LocalFeedImage(id: UUID(), description: nil, location: nil, url: url)
        
        sut.insert([image], timestamp: Date()) { error in
            XCTAssertNil(error, "Failed to save \(image) with \(error!)", file: file, line: line)
            sut.insert(data: data, for: url) { result in
                if case let .failure(error) = result {
                    XCTFail("Failed to insert \(data) with \(error)", file: file, line: line)
                }
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
