//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by x.one on 24.11.22.
//

import XCTest
import EssentialFeed

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyCacheOnEmptyCache()
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    func test_retrive_deliversFoundValuesOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
    func test_insert_overridesPreviouslyInsertedCache()
    func test_delete_doesNothingOnEmptyCache()
    func test_delete_deletesDataOnNonEmptyCache()
    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversFailureOnRetrivalError()
    func test_retrieve_hasNoSideEffectsOnRetrivalError()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversAnErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversAnErrorOnDeletionError()
}

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
