//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by x.one on 12.12.22.
//

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader,
                                        imageLoader: FeedImageDataLoader) -> FeedViewController {
        let feedLoaderPresenterAdapter = FeedLoaderPresenterAdapter()
        let refreshController = FeedRefreshViewController(loadFeed: feedLoaderPresenterAdapter.loadFeed)
        let feedViewController = FeedViewController(refreshController: refreshController)
        let feedViewAdapter = FeedViewAdapter(controller: feedViewController, imageLoader: imageLoader)
        let feedPresenter = FeedPresenter(feedLoadingView: WeakRefVirtualProxy(object: refreshController),
                                          feedView: feedViewAdapter)
        feedLoaderPresenterAdapter.feedLoader = feedLoader
        feedLoaderPresenterAdapter.presenter = feedPresenter
        return feedViewController
    }
    
}

private final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(object: T?) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    
    func display(_ viewData: FeedLoadingViewData) {
        object?.display(viewData)
    }
    
}

private class FeedViewAdapter: FeedView {
    
    private weak var feedViewController: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.feedViewController = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewData: FeedViewData) {
        feedViewController?.cellControllers = viewData.feed.map {
            let viewModel = FeedImageCellViewModel(imageLoader: imageLoader,
                                                   feedImage: $0,
                                                   imageTransformer: UIImage.init)
            return FeedImageCellController(viewModel: viewModel)
        }
    }
    
}

private class FeedLoaderPresenterAdapter {
    
    var presenter: FeedPresenter?
    var feedLoader: FeedLoader?
    
    func loadFeed() {
        presenter?.didStartLoadingFeed()
        feedLoader?.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.presenter?.didFinishLoadingFeed(with: feed)
            case .failure(let error):
                self?.presenter?.didFinishLoadingFeed(with: error)
            }
        }
    }
    
}
