//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 26.11.22.
//

import XCTest
import CoreData
import EssentialFeed

class CoreDataFeedStore: FeedStore {
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
    func insert(_ items: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        completion(.empty)
    }
    
}

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
        
    }
    
    func test_insert_overridesPreviouslyInsertedCache() {
        
    }
    
    func test_delete_doesNothingOnEmptyCache() {
        
    }
    
    func test_delete_deletesDataOnNonEmptyCache() {
        
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    private func makeSUT() -> CoreDataFeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeaks(sut)
        return sut
    }
    
    
}
