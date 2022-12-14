//
//  FeedImageViewModel.swift
//  EssentialFeediOS
//
//  Created by x.one on 13.12.22.
//

import EssentialFeed

final class FeedImageCellViewModel<Image> {
    typealias Observer<T> = (T)->Void
    
    var onLoadingStateChange: (Observer<Bool>)?
    var onImageLoad: (Observer<Image>)?
    var onShouldRetryImageLoadStateChange: (Observer<Bool>)?
    
    var location: String? {
        feedImage.location
    }
    var description: String? {
        feedImage.description
    }
    
    private var task: FeedImageDataLoaderTask?
    private let imageLoader: FeedImageDataLoader?
    private let feedImage: FeedImage
    private let imageTransformer: (Data)->Image?
    
    init(imageLoader: FeedImageDataLoader?, feedImage: FeedImage, imageTransformer: @escaping (Data)->Image?) {
        self.imageLoader = imageLoader
        self.feedImage = feedImage
        self.imageTransformer = imageTransformer
    }
    
    func loadImage() {
        onLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
        task = imageLoader?.loadImageData(from: feedImage.url) { [weak self] result in
            self?.handle(result)
        }
    }
    
    private func handle(_ result: FeedImageDataLoader.Result) {
        if let image = (try? result.get()).flatMap(imageTransformer) {
            onImageLoad?(image)
        } else {
            onShouldRetryImageLoadStateChange?(true)
        }
        onLoadingStateChange?(false)
    }
    
    func preload() {
        task = imageLoader?.loadImageData(from: feedImage.url) { _ in }
    }
    
    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
