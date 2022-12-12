//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by x.one on 12.12.22.
//

import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader,
                                        imageLoader: FeedImageDataLoader) -> FeedViewController {
        let refreshController = RefreshController(feedLoader: feedLoader)
        let feedViewController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = adaptFeedToCellControllers(forwardingTo: feedViewController, loader: imageLoader)
        return feedViewController
    }
    
    private static func adaptFeedToCellControllers(forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.cellControllers = feed.map {
            FeedImageCellController(imageLoader: loader, cellModel: $0)
        }
    }
    }
}
