//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by x.one on 12.12.22.
//

import EssentialFeed

final class FeedViewModel {
    
    private(set) var isLoading: Bool = false {
        didSet {
            onChange?(self)
        }
    }
    var onFeedLoad: (([FeedImage])->Void)?
    var onChange: ((FeedViewModel)->Void)? = nil
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.onFeedLoad?(feed)
            case .failure:
                break
            }
            self?.isLoading = false
        }
    }
    
}
