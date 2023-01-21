//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by x.one on 28.11.22.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        setupAnEmptyStoreState()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        deleteStoreArtifacts()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeFeedLoader()
        
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()
        let feedItem = uniqueItem
        
        save([feedItem], sutToPerformSave)
        expect(sutToPerformLoad, toLoad: [feedItem])
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformOverride = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()
        let firstFeedItem = uniqueItem
        let secondFeedItem = uniqueItem
        
        save([firstFeedItem], sutToPerformSave)
        save([secondFeedItem], sutToPerformOverride)
        expect(sutToPerformLoad, toLoad: [secondFeedItem])
    }
    
    func test_loadImageData_deliversItemsSavedOnASeparateInstance() {
        let feedLoader = makeFeedLoader()
        let imageLoaderToPerfromSave = makeImageDataLoader()
        let imageLoaderToPerfromLoad = makeImageDataLoader()
        let imageData = "Any Data".data(using: .utf8)!
        let feedItem = uniqueItem
        
        save([feedItem], feedLoader)
        save(imageData, for: feedItem.url, imageLoaderToPerfromSave)

        expect(imageLoaderToPerfromLoad, toLoad: imageData, for: feedItem.url)
    }
    
    private func save(_ imageData: Data, for url: URL, _ sut: LocalFeedImageDataLoader,
                      file: StaticString = #file, line: UInt = #line) {
        let saveExp = expectation(description: "wait for save completion")
        sut.save(imageData, for: url) { result in
            if case let .failure(error) = result {
                XCTFail("Expected to save feed successfully, got \(error) instead", file: file, line: line)
            }
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
    }
    
    private func save(_ feed: [FeedImage], _ sut: LocalFeedLoader,
                      file: StaticString = #file, line: UInt = #line) {
        let saveExp = expectation(description: "wait for save completion")
        sut.save(feed) { error in
            XCTAssertNil(error, "Expected to save feed successfully", file: file, line: line)
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
    }
    
    private func expect(_ sut: LocalFeedImageDataLoader, toLoad expectedData: Data, for url: URL, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for load completion")
        sut.loadImageData(from: url) { result in
            switch result {
            case .success(let receivedData):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
            case .failure(let error):
                XCTFail("expected success case with empty array, got \(error) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for load completion")
        sut.load { result in
            switch result {
            case .success(let receivedItems):
                XCTAssertEqual(receivedItems, expectedFeed, file: file, line: line)
            case .failure(let error):
                XCTFail("expected success case with empty array, got \(error) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeImageDataLoader() -> LocalFeedImageDataLoader {
        let storeURL = testSpecificStoreURL()
        let coreDataStore = try! CoreDataFeedStore(storeURL: storeURL)
        let localFeedLoader = LocalFeedImageDataLoader(store: coreDataStore)
        trackForMemoryLeaks(localFeedLoader)
        trackForMemoryLeaks(coreDataStore)
        return localFeedLoader
    }
    
    private func makeFeedLoader() -> LocalFeedLoader {
        let storeURL = testSpecificStoreURL()
        let coreDataStore = try! CoreDataFeedStore(storeURL: storeURL)
        let localFeedLoader = LocalFeedLoader(store: coreDataStore, timestamp: Date.init)
        trackForMemoryLeaks(localFeedLoader)
        trackForMemoryLeaks(coreDataStore)
        return localFeedLoader
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupAnEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

}
