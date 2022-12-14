//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit

final class FeedImageCellController {
    
    private let viewModel: FeedImageCellViewModel<UIImage>
    
    init(viewModel: FeedImageCellViewModel<UIImage>) {
        self.viewModel = viewModel
    }
    
    func view() -> UITableViewCell {
        let cell = binded(FeedImageCell())
        viewModel.loadImage()
        return cell
    }
    
    func preload() {
        viewModel.preload()
    }
    
    func cancelLoad() {
        viewModel.cancelLoad()
    }
    
    func binded(_ cell: FeedImageCell) -> UITableViewCell {
        cell.feedImageContainer.startShimmering()
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        
        cell.onRetry = viewModel.loadImage
        cell.locationLabel.isHidden = (viewModel.location == nil)
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        
        viewModel.onShouldRetryImageLoadStateChange = { [weak cell] shouldRetry in
            cell?.retryButton.isHidden = !shouldRetry
        }
        viewModel.onLoadingStateChange = { [weak cell] isLoading in
            if !isLoading { cell?.feedImageContainer.stopShimmering() }
        }
        viewModel.onImageLoad = { [weak cell] image in
            cell?.feedImageView.image = image
        }
        return cell
    }
    
}
