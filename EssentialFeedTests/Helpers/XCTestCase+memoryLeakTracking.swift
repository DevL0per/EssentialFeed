//
//  XCTestCase+memoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by x.one on 22.10.22.
//

import XCTest

extension XCTestCase {
    
    func trackForMemoryLeaks(_ instanse: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instanse] in
            XCTAssertNil(instanse, "Potential memory leak", file: file, line: line)
        }
    }
    
    func anyNSError() -> NSError {
        return NSError(domain: "", code: 100)
    }
    
}
