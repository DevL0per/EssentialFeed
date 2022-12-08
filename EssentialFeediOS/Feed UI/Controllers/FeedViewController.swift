//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by x.one on 6.12.22.
//

import UIKit
import EssentialFeed

final public class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    
    private var refreshController: RefreshController?
    private var imageLoader: FeedImageDataLoader?
    private var tableModel: [FeedImage] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var feedImageCellControllers: [IndexPath: FeedImageCellController] = [:]
    
    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.imageLoader = imageLoader
        self.refreshController = RefreshController(feedLoader: feedLoader)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
        
        refreshControl = refreshController?.view
        refreshController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }
        refreshController?.refresh()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feedImageCellController = cellController(forRowAt: indexPath)
        return feedImageCellController.view()
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let feedImageCellController = cellController(forRowAt: indexPath)
            feedImageCellController.preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            removeCellController(forRowAt: indexPath)
        }
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        removeCellController(forRowAt: indexPath)
    }
    
    private func removeCellController(forRowAt indexPath: IndexPath) {
        feedImageCellControllers[indexPath] = nil
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        let cellModel = tableModel[indexPath.row]
        let feedImageCellController = FeedImageCellController(imageLoader: imageLoader, cellModel: cellModel)
        feedImageCellControllers[indexPath] = feedImageCellController
        return feedImageCellController
    }
    
}
