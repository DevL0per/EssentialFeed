//
//  RefreshController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit
 
final class FeedRefreshViewController: NSObject {
    
    lazy var view: UIRefreshControl = {
        return binded(UIRefreshControl())
    }()
    
    private let viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingStateChange = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
    
}
