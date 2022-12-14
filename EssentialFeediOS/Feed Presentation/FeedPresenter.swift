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
    
    var feedLoadingView: FeedLoadingView?
    var feedView: FeedView?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedLoadingView?.display(FeedLoadingViewData(isLoading: true))
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.feedView?.display(FeedViewData(feed: feed))
            case .failure:
                break
            }
            self?.feedLoadingView?.display(FeedLoadingViewData(isLoading: false))
        }
    }
    
}

