//
//  FeedImageCellPresenterTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 5.01.23.
//

import XCTest
import EssentialFeed

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
}

protocol FeedImageView {
    associatedtype Image
    
    func display(_ viewModel: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> {
    
    private let view: View
    
    init(view: View) {
        self.view = view
    }
    
    func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(description: model.description,
                                        location: model.location,
                                        image: nil,
                                        isLoading: true,
                                        shouldRetry: false))
    }
}

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
    
    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line)
    -> (FeedImagePresenter<ViewSPY, AnyImage>, ViewSPY) {
        let view = ViewSPY()
        let sut = FeedImagePresenter<ViewSPY, AnyImage>(view: view)
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