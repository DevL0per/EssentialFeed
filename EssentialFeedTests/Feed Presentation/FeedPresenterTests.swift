//
//  FeedPresenter.swift
//  EssentialFeedTests
//
//  Created by x.one on 4.01.23.
//

import XCTest

final class FeedPresenter {
    
}

final class FeedPresenterTests: XCTestCase {

    final class ViewSPY {
        var messages: [Any] = []
    }
    
    func test_init_doesNotSendMessagesToView() {
        let view = ViewSPY()
        let _ = FeedPresenter()
        XCTAssertTrue(view.messages.isEmpty)
    }

}
