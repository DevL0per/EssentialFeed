//
//  FeedImageCellPresenterTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 5.01.23.
//

import XCTest
import EssentialFeed

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotLoadImage() {
        let (_, view) = makeSUT()
        XCTAssertEqual(view.messages.count, 0)
    }
    
    func test_didStartLoadingImageData_displaysLoadingImage() {
        let (sut, view) = makeSUT()
        let url = URL(string: "http://anyURL.com")!
        let feedImage = FeedImage(id: UUID(), description: "any", location: "any", url: url)
        
        sut.didStartLoadingImageData(for: feedImage)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, feedImage.description)
        XCTAssertEqual(message?.location, feedImage.location)
        XCTAssertEqual(message?.image, nil)
        XCTAssertEqual(message?.isLoading, true)
        XCTAssertEqual(message?.shouldRetry, false)
    }
    
    func test_didFinishLoadingImageDataWithError_displaysRetry() {
        let transformedImage = AnyImage()
        let (sut, view) = makeSUT(transformer: { _ in return transformedImage })
        let url = URL(string: "http://anyURL.com")!
        let feedImage = FeedImage(id: UUID(), description: "any", location: "any", url: url)
        let error = anyNSError()
        
        sut.didFinishLoadingImageData(with: error, for: feedImage)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, feedImage.description)
        XCTAssertEqual(message?.location, feedImage.location)
        XCTAssertNil(message?.image)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
    }
    
    func test_didFinishLoadingImageData_displaysRetryOnFailedTransformation() {
        let (sut, view) = makeSUT(transformer: { _ in return nil })
        let url = URL(string: "http://anyURL.com")!
        let feedImage = FeedImage(id: UUID(), description: "any", location: "any", url: url)
        
        sut.didFinishLoadingImageData(with: Data(), for: feedImage)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, feedImage.description)
        XCTAssertEqual(message?.location, feedImage.location)
        XCTAssertNil(message?.image)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
    }
    
    func test_didFinishLoadingImageData_displaysImageOnSuccessfulTransformation() {
        let transformedImage = AnyImage()
        let (sut, view) = makeSUT(transformer: { _ in return transformedImage })
        let url = URL(string: "http://anyURL.com")!
        let feedImage = FeedImage(id: UUID(), description: "any", location: "any", url: url)
        
        sut.didFinishLoadingImageData(with: Data(), for: feedImage)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, feedImage.description)
        XCTAssertEqual(message?.location, feedImage.location)
        XCTAssertEqual(message?.image, transformedImage)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, false)
    }
    
    private func makeSUT(file: StaticString = #file,
                         transformer: @escaping ((Data)->AnyImage?) = { _ in nil },
                         line: UInt = #line)
    -> (FeedImagePresenter<ViewSPY, AnyImage>, ViewSPY) {
        let view = ViewSPY()
        let sut = FeedImagePresenter<ViewSPY, AnyImage>(view: view, imageTransrormer: transformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    private class ViewSPY: FeedImageView {
        typealias Image = AnyImage
        
        var messages: [FeedImageViewModel<AnyImage>] = []
        
        func display(_ viewModel: FeedImageViewModel<FeedImagePresenterTests.AnyImage>) {
            messages.append(viewModel)
        }
    }
    
    private struct AnyImage: Equatable {}
}
