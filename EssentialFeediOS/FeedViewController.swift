//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by x.one on 6.12.22.
//

import UIKit
import EssentialFeed

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    func loadImageData(from url: URL, completion: @escaping (Result)->Void) -> FeedImageDataLoaderTask
}

final public class FeedViewController: UITableViewController {
    
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageDataLoader?
    private var tableModel: [FeedImage] = []
    private var imageLoaderTasks: [IndexPath: FeedImageDataLoaderTask] = [:]
    
    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.imageLoader = imageLoader
        self.feedLoader = feedLoader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        
        load()
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        feedLoader?.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.tableModel = feed
            case .failure:
                break
            }
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
        }
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
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        imageLoaderTasks[indexPath]?.cancel()
    }
    
}
