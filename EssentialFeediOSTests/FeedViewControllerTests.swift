//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by x.one on 5.12.22.
//

import XCTest
import UIKit
import EssentialFeediOS
import EssentialFeed

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.feedRequestsCallCount, 0)
    }
    
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.feedRequestsCallCount, 0)
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.feedRequestsCallCount, 1)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.feedRequestsCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.feedRequestsCallCount, 3)
    }
    
    func test_loadingFeedIndicatorIsVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndocator())
        
        loader.completeLoading()
        XCTAssertFalse(sut.isShowingLoadingIndocator())
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndocator())
        
        loader.completeLoading(atIndex: 1)
        XCTAssertFalse(sut.isShowingLoadingIndocator())
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeLoadingWithError(atIndex: 2)
        XCTAssertFalse(sut.isShowingLoadingIndocator())
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "description", location: "location")
        let image1 = makeImage(description: nil, location: "location 1")
        let image2 = makeImage(description: "description 2", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        loader.completeLoading(with: [image0])
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeLoading(with: [image0, image1, image2, image3])
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "description", location: "location")
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(with: [image0])
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeLoadingWithError()
        assertThat(sut, isRendering: [image0])
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(with: [image0, image1])
        
        XCTAssertEqual(loader.loadedImageURLs, [])
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url])
        
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url])
        
    }
    
    func test_feedImageView_cancelsImageLoadingWhenNotVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(with: [image0, image1])
        
        XCTAssertEqual(loader.canceledURLs, [])
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.canceledURLs, [image0.url])
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.canceledURLs, [image0.url, image1.url])
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(with: [image0, image1])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, true)
        XCTAssertEqual(view1?.isShowingLoadingIndicator, true)
        
        loader.completeImageDataLoading(atIndex: 0)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false)
        XCTAssertEqual(view1?.isShowingLoadingIndicator, true)
        
        loader.completeImageDataLoadingWithError(atIndex: 1)
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false)
        XCTAssertEqual(view1?.isShowingLoadingIndicator, false)
    }

    class LoaderSpy: FeedLoader, FeedImageDataLoader {
        
        // MARK: - FeedLoader
        typealias LoadCompletion = (FeedLoaderResult) -> Void
        var feedRequestsCallCount: Int { feedRequests.count }
        private var feedRequests: [LoadCompletion] = []
        
        // MARK: - FeedLoader
        func load(completion: @escaping (FeedLoaderResult) -> Void) {
            self.feedRequests.append(completion)
        }
        
        func completeLoading(with feed: [FeedImage] = [], atIndex index: Int = 0) {
            feedRequests[index](.success(feed))
        }
        
        func completeLoadingWithError(atIndex index: Int = 0) {
            let error = NSError(domain: "", code: 1)
            feedRequests[index](.failure(error))
        }
        
        // MARK: - FeedImageDataLoader
        var loadedImageURLs: [URL] { imageRequests.map { $0.url } }
        
        private var imageRequests = [(url: URL, completion: (FeedImageDataLoader.Result)->Void)]()
        private(set) var canceledURLs: [URL] = []
        
        func loadImageData(from url: URL,
                           completion: @escaping (Result<Data, Error>)->Void) -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return FeedImageDataLoaderTaskSpy { [weak self] in self?.canceledURLs.append(url) }
        }

        func completeImageDataLoading(with imageData: Data = Data(), atIndex index: Int = 0) {
            imageRequests[index].completion(.success(imageData))
        }
        
        func completeImageDataLoadingWithError(atIndex index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            imageRequests[index].completion(.failure(error))
        }
        
    }
    
    private struct FeedImageDataLoaderTaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: ()->Void
        
        func cancel() {
            cancelCallback()
        }
    }
    
    private func assertThat(_ sut: FeedViewController, isRendering images: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(sut.numberOfRenderedFeedImageViews, images.count, file: file, line: line)
        images.enumerated().forEach {
            assertThat(sut, hasViewConfiguredFor: $1, at: $0, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let shouldLocationBeVisible = !(image.location == nil)
        let renderedView = sut.feedImageView(atIndex: index)
        XCTAssertNotNil(renderedView, file: file, line: line)
        XCTAssertEqual(renderedView?.isShowingLocation, shouldLocationBeVisible, file: file, line: line)
        XCTAssertEqual(renderedView?.descriptionText, image.description, file: file, line: line)
        XCTAssertEqual(renderedView?.locationText, image.location, file: file, line: line)
    }
    
    private func makeImage(id: UUID = UUID(), description: String? = nil, location: String? = nil, url: URL = URL(string: "testURL.com")!) -> FeedImage {
        return FeedImage(id: id, description: description, location: location, url: url)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(feedLoader: loader, imageLoader: loader)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (sut, loader)
    }
}

private extension FeedImageCell {
    
    var isShowingLoadingIndicator: Bool {
        feedImageContainer.isShimmering
    }
    
    var isShowingLocation: Bool {
        !locationLabel.isHidden
    }
    
    var descriptionText: String? {
        descriptionLabel.text
    }
    
    var locationText: String? {
        locationLabel.text
    }
    
}

private extension FeedViewController {
    private var feedImagesSection: Int { return 0 }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(atIndex: index)
    }
    
    func simulateFeedImageViewNotVisible(at index: Int) {
        let visibleCell = simulateFeedImageViewVisible(at: index)
        let delegate = tableView.delegate
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: visibleCell!, forRowAt: indexPath)
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func isShowingLoadingIndocator() -> Bool {
        refreshControl?.isRefreshing ?? false
    }
    
    var numberOfRenderedFeedImageViews: Int {
        self.tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(atIndex index: Int) -> FeedImageCell? {
        let ds = tableView.dataSource
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: indexPath) as? FeedImageCell
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
