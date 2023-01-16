//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by x.one on 22.10.22.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult_mathcesFixedTestAccountData() {
        let url = feedTestSevertURL
        let client = URLSessionHTTPClient(urlSession: .shared)
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        
        let expectation = expectation(description: "waiting for completion")
        sut.load { result in
            switch result {
            case .success(let feedItems):
                XCTAssertEqual(feedItems.count, 8)
            case .failure:
                XCTFail("expected data from API")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 8)
    }
    
    func test_endToEndTestServerGETFeedImageDataResult_machesFixedTestAccountData() {
        let testServerURL = feedTestSevertURL.appendingPathComponent("73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")
        let client = URLSessionHTTPClient(urlSession: .shared)
        let loader = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(client)
        
        let exp = expectation(description: "wait for loadImageData completion")
        
        loader.loadImageData(from: testServerURL) { result in
            switch result {
            case let .success(imageData):
                XCTAssertTrue(!imageData.isEmpty)
            default:
                XCTFail("expected success result with non empty data, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 8)
    }
    
    private var feedTestSevertURL: URL {
        return URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
    }
    
    
}
