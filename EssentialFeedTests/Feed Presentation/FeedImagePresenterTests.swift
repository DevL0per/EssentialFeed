//
//  FeedImageCellPresenterTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 5.01.23.
//

import XCTest
import EssentialFeed

final class FeedImagePresenter {
    
    init(view: Any) {
        
    }
    
}

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotLoadImage() {
        let (_, view) = makeSUT()
        XCTAssertEqual(view.messages, [])
    }
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (FeedImagePresenter, ViewSPY) {
        let view = ViewSPY()
        let sut = FeedImagePresenter(view: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    private class ViewSPY {
        var messages: [String] = []
    }
}
