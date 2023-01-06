//
//  FeedImagePresenter.swift
//  EssentialFeed
//
//  Created by x.one on 6.01.23.
//

import Foundation

final public class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    
    private let view: View
    private let imageTransrormer: (Data)->Image?
    
    public init(view: View, imageTransrormer: @escaping (Data)->Image?) {
        self.view = view
        self.imageTransrormer = imageTransrormer
    }
    
    public func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(description: model.description,
                                        location: model.location,
                                        image: nil,
                                        isLoading: true,
                                        shouldRetry: false))
    }
    
    public func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        view.display(FeedImageViewModel(description: model.description,
                                        location: model.location,
                                        image: nil,
                                        isLoading: false,
                                        shouldRetry: true))
    }
    
    public func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        let transformedImage = imageTransrormer(data)
        let shouldRetry = (transformedImage == nil)
        view.display(FeedImageViewModel(description: model.description,
                                        location: model.location,
                                        image: transformedImage,
                                        isLoading: false,
                                        shouldRetry: shouldRetry))
    }
}
