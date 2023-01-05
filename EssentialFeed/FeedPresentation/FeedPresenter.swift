//
//  FeedPresenter.swift
//  EssentialFeed
//
//  Created by x.one on 5.01.23.
//

import Foundation

public struct FeedLoadingViewData {
    public let isLoading: Bool
}

public protocol FeedLoadingView: AnyObject {
    func display(_ viewData: FeedLoadingViewData)
}

public struct FeedViewData {
    public let feed: [FeedImage]
}

public protocol FeedView: AnyObject {
    func display(_ viewData: FeedViewData)
}

public final class FeedPresenter {
    
    private let feedLoadingView: FeedLoadingView
    private let feedView: FeedView
    
    public init(feedLoadingView: FeedLoadingView, feedView: FeedView) {
        self.feedLoadingView = feedLoadingView
        self.feedView = feedView
    }
    
    public static var title: String {
        return NSLocalizedString("FEED_VIEW_TITLE",
                                 tableName: "Feed",
                                 bundle: Bundle(for: FeedPresenter.self),
                                 comment: "")
    }
    
    public func didStartLoadingFeed() {
        feedLoadingView.display(FeedLoadingViewData(isLoading: true))
    }
    
    public func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewData(feed: feed))
        feedLoadingView.display(FeedLoadingViewData(isLoading: false))
    }
    
    public func didFinishLoadingFeed(with error: Error) {
        feedLoadingView.display(FeedLoadingViewData(isLoading: false))
    }
}
