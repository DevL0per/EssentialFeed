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
    private var imageLoaderTasks: [IndexPath: FeedImageDataLoaderTask] = [:]
    
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
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationLabel.isHidden = (cellModel.location == nil)
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        cell.feedImageContainer.startShimmering()
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            self.imageLoaderTasks[indexPath] = self.imageLoader?.loadImageData(from: cellModel.url) { [weak cell] result in
                cell?.feedImageContainer.stopShimmering()
                guard let imageData = try? result.get(), let image = UIImage(data: imageData) else {
                    cell?.retryButton.isHidden = false
                    return
                }
                cell?.feedImageView.image = image
            }
        }
        loadImage()
        cell.onRetry = loadImage
        return cell
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let cellModel = tableModel[indexPath.row]
            let task = imageLoader?.loadImageData(from: cellModel.url) { _ in }
            imageLoaderTasks[indexPath] = task
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cancelTask(forRowAt: indexPath)
        }
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(forRowAt: indexPath)
    }
    
    private func cancelTask(forRowAt indexPath: IndexPath) {
        imageLoaderTasks[indexPath]?.cancel()
        imageLoaderTasks[indexPath] = nil
    }
    
}
