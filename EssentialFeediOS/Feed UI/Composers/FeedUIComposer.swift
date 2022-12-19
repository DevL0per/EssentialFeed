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
        let feedPresenter = FeedPresenter(feedLoader: feedLoader)
        let feedLoaderPresenterAdapter = FeedLoaderPresenterAdapter(presenter: feedPresenter, feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(loadFeed: feedLoaderPresenterAdapter.loadFeed)
        let feedViewController = FeedViewController(refreshController: refreshController)
        let feedViewAdapter = FeedViewAdapter(controller: feedViewController, imageLoader: imageLoader)
        feedPresenter.feedLoadingView = WeakRefVirtualProxy(object: refreshController)
        feedPresenter.feedView = feedViewAdapter
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
    
    private let presenter: FeedPresenter
    private let feedLoader: FeedLoader
    
    init(presenter: FeedPresenter, feedLoader: FeedLoader) {
        self.presenter = presenter
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        presenter.didStartLoadingFeed()
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.presenter.didFinishLoadingFeed(with: feed)
            case .failure(let error):
                self?.presenter.didFinishLoadingFeed(with: error)
            }
        }
    }
    
}
