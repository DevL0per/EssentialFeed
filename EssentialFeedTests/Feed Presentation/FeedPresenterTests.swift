//
//  FeedPresenter.swift
//  EssentialFeedTests
//
//  Created by x.one on 4.01.23.
//

import XCTest
import EssentialFeed

struct FeedLoadingViewData {
    let isLoading: Bool
}

protocol FeedLoadingView: AnyObject {
    func display(_ viewData: FeedLoadingViewData)
}

struct FeedViewData {
    let feed: [FeedImage]
}

protocol FeedView: AnyObject {
    func display(_ viewData: FeedViewData)
}

final class FeedPresenter {
    
    private let feedLoadingView: FeedLoadingView
    private let feedView: FeedView
    
    init(feedLoadingView: FeedLoadingView, feedView: FeedView) {
        self.feedLoadingView = feedLoadingView
        self.feedView = feedView
    }
    
    func didStartLoadingFeed() {
        feedLoadingView.display(FeedLoadingViewData(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewData(feed: feed))
        feedLoadingView.display(FeedLoadingViewData(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        feedLoadingView.display(FeedLoadingViewData(isLoading: false))
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
    
    func test_didFinishLoadingFeed_displaysFeedAndStopsLoading() {
        let (sut, view) = makeSUT()
        let feedImages = [uniqueItem, uniqueItem]
        sut.didFinishLoadingFeed(with: feedImages)
        
        XCTAssertEqual(view.messages, [.display(feed: feedImages), .display(isLoading: false)])
    }
    
    func test_didFinishLoadingFeedWithError_stopsLoading() {
        let (sut, view) = makeSUT()
        let error = anyNSError()
        sut.didFinishLoadingFeed(with: error)
        
        XCTAssertEqual(view.messages, [.display(isLoading: false)])
    }

    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (FeedPresenter, ViewSPY) {
        let view = ViewSPY()
        let sut = FeedPresenter(feedLoadingView: view, feedView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    private class ViewSPY: FeedLoadingView, FeedView {
        enum Message: Hashable {
            case display(isLoading: Bool)
            case display(feed: [FeedImage])
        }
        var messages: Set<Message> = []
        
        func display(_ viewData: FeedViewData) {
            messages.insert(.display(feed: viewData.feed))
        }
        
        func display(_ viewData: FeedLoadingViewData) {
            messages.insert(.display(isLoading: viewData.isLoading))
        }
    }
}
