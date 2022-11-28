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
        let sut = makeSUT()
        
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = uniqueItem
        
        let saveExp = expectation(description: "wait for save completion")
        sutToPerformSave.save([feed]) { error in
            XCTAssertNil(error, "expected to save successfully")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
        
        expect(sutToPerformLoad, toLoad: [feed])
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
    
    private func makeSUT() -> LocalFeedLoader {
        let storeURL = testSpecificStoreURL()
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let coreDataStore = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
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
