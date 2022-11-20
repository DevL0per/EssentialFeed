//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 20.11.22.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    typealias RetrivalCompletion = (RetriveCachedFeedResult)->Void
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    func test_retrieve_deliversEmptyCacheOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "wait for cache retrieval")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "wait for cache retrieval")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected empty result, got \(firstResult) and \(secondResult) instead")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}
