//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit
import EssentialFeed

final class FeedImageCellController {
    
    private var task: FeedImageDataLoaderTask?
    private let imageLoader: FeedImageDataLoader?
    private let cellModel: FeedImage
    
    init(imageLoader: FeedImageDataLoader?, cellModel: FeedImage) {
        self.imageLoader = imageLoader
        self.cellModel = cellModel
    }
    
    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationLabel.isHidden = (cellModel.location == nil)
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        cell.feedImageContainer.startShimmering()
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            self.task = self.imageLoader?.loadImageData(from: self.cellModel.url) { [weak cell] result in
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
    
    func preload() {
        task = imageLoader?.loadImageData(from: self.cellModel.url) { _ in }
    }
    
    func cancelLoad() {
        task?.cancel()
    }
    
}
