//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by x.one on 14.12.22.
//

import EssentialFeed

protocol FeedLoadingView: AnyObject {
    func display(isLoading: Bool)
}

protocol FeedView: AnyObject {
    func display(feed: [FeedImage])
}

final class FeedPresenter {
    
    var feedLoadingView: FeedLoadingView?
    var feedView: FeedView?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedLoadingView?.display(isLoading: true)
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.feedView?.display(feed: feed)
            case .failure:
                break
            }
            self?.feedLoadingView?.display(isLoading: false)
        }
    }
    
}

