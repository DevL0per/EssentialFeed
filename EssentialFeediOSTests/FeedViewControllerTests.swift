//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by x.one on 5.12.22.
//

import XCTest

final class FeedViewController {
    let loader: FeedViewControllerTests.LoaderSpy
    
    init(loader: FeedViewControllerTests.LoaderSpy) {
        self.loader = loader
    }
}

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        let _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    class LoaderSpy {
        private(set) var loadCallCount: Int = 0
    }
}
