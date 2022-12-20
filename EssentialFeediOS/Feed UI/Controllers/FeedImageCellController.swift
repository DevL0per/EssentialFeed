//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit

final class FeedImageCellController {
    
    private let viewModel: FeedImageCellViewModel<UIImage>
    private var cell: FeedImageCell?
    
    init(viewModel: FeedImageCellViewModel<UIImage>) {
        self.viewModel = viewModel
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        cell = binded(tableView.dequeueReusableCell())
        viewModel.loadImage()
        return cell!
    }
    
    func preload() {
        viewModel.preload()
    }
    
    func cancelLoad() {
        releaseCellForReuse()
        viewModel.cancelLoad()
    }
    
    func binded(_ cell: FeedImageCell) -> FeedImageCell {
        cell.feedImageContainer.startShimmering()
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        
        cell.onRetry = viewModel.loadImage
        cell.locationLabel.isHidden = (viewModel.location == nil)
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        
        viewModel.onShouldRetryImageLoadStateChange = { [weak self] shouldRetry in
            self?.cell?.retryButton.isHidden = !shouldRetry
        }
        viewModel.onLoadingStateChange = { [weak self] isLoading in
            if !isLoading { self?.cell?.feedImageContainer.stopShimmering() }
        }
        viewModel.onImageLoad = { [weak self] image in
            self?.cell?.feedImageView.image = image
        }
        return cell
    }
    
    private func  releaseCellForReuse() {
        cell = nil
    }
    
}
