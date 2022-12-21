//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by x.one on 14.12.22.
//

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
    
    static var title: String {
        return "My Feed"
    }
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
