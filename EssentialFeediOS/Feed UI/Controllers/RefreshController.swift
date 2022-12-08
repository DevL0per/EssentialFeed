//
//  RefreshController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit
import EssentialFeed

final class RefreshController: NSObject {
    
    lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl.beginRefreshing()
        return refreshControl
    }()
    var onRefresh: (([FeedImage])->Void)?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    @objc func refresh() {
        view.beginRefreshing()
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.onRefresh?(feed)
            case .failure: break
            }
            self?.view.endRefreshing()
        }
    }
    
}
