//
//  FeedPresenter.swift
//  EssentialFeedTests
//
//  Created by x.one on 4.01.23.
//

import XCTest

struct FeedLoadingViewData {
    let isLoading: Bool
}

protocol FeedLoadingView: AnyObject {
    func display(_ viewData: FeedLoadingViewData)
}

final class FeedPresenter {
    private let feedLoadingView: FeedLoadingView
    
    init(feedLoadingView: FeedLoadingView) {
        self.feedLoadingView = feedLoadingView
    }
    
    func didStartLoadingFeed() {
        feedLoadingView.display(FeedLoadingViewData(isLoading: true))
    }
}

final class FeedPresenterTests: XCTestCase {

    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    func test_didStartLoadingFeed_startsLoading() {
        let (sut, view) = makeSUT()
        sut.didStartLoadingFeed()
        XCTAssertEqual(view.messages, [.display(isLoading: true)])
    }

    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (FeedPresenter, ViewSPY) {
        let view = ViewSPY()
        let sut = FeedPresenter(feedLoadingView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    private class ViewSPY: FeedLoadingView {
        enum Message: Equatable {
            case display(isLoading: Bool)
        }
        var messages: [Message] = []
        
        func display(_ viewData: FeedLoadingViewData) {
            messages.append(.display(isLoading: viewData.isLoading))
        }
    }
}
