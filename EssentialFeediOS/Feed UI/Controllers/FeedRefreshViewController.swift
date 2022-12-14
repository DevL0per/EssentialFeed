//
//  RefreshController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit
 
final class FeedRefreshViewController: NSObject {
    
    lazy var view: UIRefreshControl = {
        return loadView()
    }()
    
    private let presenter: FeedPresenter
    
    init(presenter: FeedPresenter) {
        self.presenter = presenter
    }
    
    @objc func refresh() {
        presenter.loadFeed()
    }
    
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
    
}

extension FeedRefreshViewController: FeedLoadingView {
    
    func display(isLoading: Bool) {
        if isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
    
}
