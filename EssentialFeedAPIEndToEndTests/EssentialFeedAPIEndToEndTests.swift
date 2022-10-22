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
        let url = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
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
        wait(for: [expectation], timeout: 10)
    }
    
    
}
