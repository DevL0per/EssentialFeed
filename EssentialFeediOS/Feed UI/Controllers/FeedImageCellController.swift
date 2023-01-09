//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by x.one on 8.12.22.
//

import UIKit
import EssentialFeed

protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}

final class FeedImageCellController: FeedImageView {
    
    typealias Image = UIImage
    
    private let delegate: FeedImageCellControllerDelegate
    private var cell: FeedImageCell?
    
    init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()
        cell!.onRetry = { [weak self] in
            self?.delegate.didRequestImage()
        }
        delegate.didRequestImage()
        return cell!
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelImageRequest()
    }
    
    func display(_ viewModel: FeedImageViewModel<Image>) {
        if viewModel.isLoading {
            cell?.feedImageContainer.startShimmering()
        } else {
            cell?.feedImageContainer.stopShimmering()
        }
        cell?.feedImageView.image = viewModel.image
        cell?.retryButton.isHidden = !viewModel.shouldRetry
        cell?.locationLabel.isHidden = (viewModel.location == nil)
        cell?.locationLabel.text = viewModel.location
        cell?.descriptionLabel.text = viewModel.description
    }
    
    private func  releaseCellForReuse() {
        cell = nil
    }
    
}
