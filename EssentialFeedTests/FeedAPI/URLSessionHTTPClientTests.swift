//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by x.one on 15.10.22.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask
}

protocol HTTPDataTask {
    func resume()
}

// Вопрос
class HttpSessionClass: HTTPSession {
    
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask {
        return URLSession.shared.dataTask(with: url, completionHandler: completionHandler)
    }
    
}

extension URLSessionDataTask: HTTPDataTask {}

// MARK: - Tests
final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUpWithError() throws {
        URLProtocolStub.startInteractingRequests()
    }
    
    override func tearDownWithError() throws {
        URLProtocolStub.stopInteractingRequests()
    }
    
    func test_get_failsOnRequstError() {
        let error = NSError(domain: "any error", code: 1)

        let receivedError = resultErrorFor(data: nil, response: nil, error: error)
        
        XCTAssertEqual((receivedError as? NSError)?.domain, error.domain)
        XCTAssertEqual((receivedError as? NSError)?.code, error.code)
    }
    
    func test_get_getFromURLPerformsGetRequestWithURL() {
        let url = URL(string: "http://any-url.com")!
        let sut = makeSUT()
        let expectaion = expectation(description: "wait for complection")
                
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectaion.fulfill()
        }
        sut.get(from: url) { _ in }
        
        wait(for: [expectaion], timeout: 1)
    }

    func test_get_getFromURLOnAllInvalidCases() {
        let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPResponse = HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyData = Data("Any".utf8)
        let anyError = NSError(domain: "", code: 400)

        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPResponse, error: nil))
    }

    func test_get_suceedsOnHTTPURLResponseWithData() {
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data("Any".utf8)

        URLProtocolStub.stub(error: nil, response: response, data: anyData)

        let values = resultValuesFor(data: anyData, response: response, error: nil)
        XCTAssertEqual(values.data, anyData)
        XCTAssertEqual(values.response?.statusCode, response?.statusCode)
    }

    func test_get_suceedsWithEmptyDataOnHTTPURLResonseWithNoData() {
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)

        let values = resultValuesFor(data: nil, response: response, error: nil)
        let emptyData = Data()
        XCTAssertEqual(values.data, emptyData)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http/google.com")!
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?,
                                 error: Error?, file: StaticString = #file,
                                 line: UInt = #line) -> (response: HTTPURLResponse?, data: Data?) {
        let result = resultFor(data: data, response: response, error: error)
        var receivedResponse: HTTPURLResponse?
        var receivedData: Data?
        switch result {
        case let .success(response, data):
            receivedResponse = response
            receivedData = data
        default:
            XCTFail("expected error")
        }
        return (receivedResponse, receivedData)
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?,
                                error: Error?, file: StaticString = #file,
                                line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)
        var receivedError: Error?
        switch result {
        case .failure(let error):
            receivedError = error
        default:
            XCTFail("expected error")
        }
        return receivedError
    }
    
    private func resultFor(data: Data?, response: URLResponse?,
                           error: Error?, file: StaticString = #file,
                           line: UInt = #line) -> HTTPClientResult {
        let url = anyURL()
        let sut = makeSUT()
        let expectaion = expectation(description: "wait for complection")
        
        URLProtocolStub.stub(error: error, response: response, data: data)
        var receivedResult: HTTPClientResult!
        sut.get(from: url) { result in
            receivedResult = result
            expectaion.fulfill()
        }
        
        wait(for: [expectaion], timeout: 1)
        return receivedResult
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut)
        return sut
    }
    
    class URLProtocolStub: URLProtocol {
      
        static var stub: Stub?
        static var requestObserver: ((URLRequest)->Void)?
        
        struct Stub {
            let error: Error?
            let response: URLResponse?
            let data: Data?
        }
   
        static func stub(error: Error? = nil, response: URLResponse? = nil, data: Data? = nil) {
            stub = Stub(error: error, response: response, data: data)
        }
        
        static func observeRequest(completion: @escaping (URLRequest)->Void) {
            requestObserver = completion
        }
        
        static func startInteractingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInteractingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let observer = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return observer(request)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
        
    }

}
