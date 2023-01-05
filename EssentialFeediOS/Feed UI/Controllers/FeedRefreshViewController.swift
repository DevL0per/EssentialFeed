//
//  RefreshController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit
import EssentialFeed

final class FeedRefreshViewController: NSObject {
    
    lazy var view: UIRefreshControl = {
        return loadView()
    }()
    
    private let loadFeed: ()->Void
    
    init(loadFeed: @escaping ()->Void) {
        self.loadFeed = loadFeed
    }
    
    @objc func refresh() {
        loadFeed()
    }
    
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
    
}

extension FeedRefreshViewController: FeedLoadingView {
    
    func display(_ viewData: FeedLoadingViewData) {
        if viewData.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
    
}
