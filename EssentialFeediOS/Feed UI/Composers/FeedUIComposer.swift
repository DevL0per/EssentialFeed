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
        refreshController.onRefresh = { [weak feedViewController] feed in
            feedViewController?.cellControllers = feed.map {
                FeedImageCellController(imageLoader: imageLoader, cellModel: $0)
            }
        }
        return feedViewController
    }
}
