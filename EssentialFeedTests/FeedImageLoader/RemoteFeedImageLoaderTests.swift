//
//  RemoteFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 10.01.23.
//

import XCTest
import EssentialFeed

final class RemoteFeedImageLoader {
        
    init(client: Any) {
    }
    
}

final class RemoteFeedImageLoaderTests: XCTestCase {

    func test_init_doesNotPerfrormAnyURLRequests() {
        let (_, client) = makeSUT()
        XCTAssertEqual(client.requestedURLs, [])
    }
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (RemoteFeedImageLoader, HTTPClientSPY) {
        let client = HTTPClientSPY()
        let sut = RemoteFeedImageLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private class HTTPClientSPY {
        var requestedURLs = [URL]()
    }

}
