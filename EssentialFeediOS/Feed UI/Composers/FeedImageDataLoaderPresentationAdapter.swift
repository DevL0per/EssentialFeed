//
//  FeedImageDataLoaderPresentationAdapter.swift
//  EssentialFeediOS
//
//  Created by x.one on 6.01.23.
//

import UIKit
import EssentialFeed

final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    
    var presenter: FeedImagePresenter<View, Image>?
    
    private var task: FeedImageDataLoaderTask?
    private let imageLoader: FeedImageDataLoader?
    private let feedImage: FeedImage
    
    init(imageLoader: FeedImageDataLoader?, feedImage: FeedImage) {
        self.imageLoader = imageLoader
        self.feedImage = feedImage
    }
    
    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: feedImage)
        let feedImage = feedImage
        task = imageLoader?.loadImageData(from: feedImage.url) { [weak self] result in
            switch result {
            case .success(let loadedData):
                self?.presenter?.didFinishLoadingImageData(with: loadedData, for: feedImage)
            case .failure(let error):
                self?.presenter?.didFinishLoadingImageData(with: error, for: feedImage)
            }
        }
    }
    
    func didCancelImageRequest() {
        task?.cancel()
        task = nil
    }
}
