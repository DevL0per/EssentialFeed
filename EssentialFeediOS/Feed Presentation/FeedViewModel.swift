//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by x.one on 12.12.22.
//

import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T)->Void
    
    var onFeedLoad: (Observer<[FeedImage]>)?
    var onLoadingStateChange: (Observer<Bool>)? = nil
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.onFeedLoad?(feed)
            case .failure:
                break
            }
            self?.onLoadingStateChange?(false)
        }
    }
    
}
