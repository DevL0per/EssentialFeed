//
//  FeedPresenter.swift
//  EssentialFeedTests
//
//  Created by x.one on 4.01.23.
//

import XCTest
import EssentialFeed

final class FeedPresenterTests: XCTestCase {
    
    func test_title_isLocalized() {
        XCTAssertEqual(FeedPresenter.title, localized("FEED_VIEW_TITLE"))
    }

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
    
    private func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        let table = "Feed"
        let value = bundle.localizedString(forKey: key, value: nil, table: "Feed")
        
        XCTAssertNotEqual(value, key, "missing localization for key: \(key) in table \(table)", file: file, line: line)
        return value
    }
}
