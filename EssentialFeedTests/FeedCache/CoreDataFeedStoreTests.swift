//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 26.11.22.
//

import XCTest
import CoreData
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyCacheOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveDeliversEmptyCacheOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrive_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetriveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        assertThatInsertOverridesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_doesNothingOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteDoesNothingOnEmptyCache(on: sut)
    }
    
    func test_delete_deletesDataOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteDeletesDataOnNonEmptyCache(sut: sut)
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    
}
