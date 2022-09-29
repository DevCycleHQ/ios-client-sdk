//
//  RequestConsolidatorTests.swift
//  DevCycleTests
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import XCTest
@testable import DevCycle

class RequestConsolidatorTests: XCTestCase {

    func testOneRequestFinishes() {
        let mockService = MockService()
        let requestConsolidator = RequestConsolidator(service: mockService)
        let request = URLRequest(url: URL(string: "https://dummy.com")!)
        let expectation = expectation(description: "One request completes")
        requestConsolidator.queue(request: request) { response in
            XCTAssertEqual(response.config?.variables["testVar"]?.value as! String, "any_value")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertFalse(requestConsolidator.requestInFlight)
    }
    
    func testMultipleRequestFinishesWithLatestURLConfig() {
        let mockService = MockService()
        let requestConsolidator = RequestConsolidator(service: mockService)
        let request1 = URLRequest(url: URL(string: "https://dummy.com/firstPage")!)
        let request2 = URLRequest(url: URL(string: "https://dummy.com/secondPage")!)
        let request3 = URLRequest(url: URL(string: "https://dummy.com/thirdPage")!)
        let expectation = expectation(description: "Multiple request completes")
        expectation.expectedFulfillmentCount = 3
        requestConsolidator.queue(request: request1) { response in
            print("testVar variable 1: \(response.config?.variables["testVar"]?.value as! String)")
            XCTAssertEqual(response.config?.variables["testVar"]?.value as! String, "thirdPage")
            print("Fulfill 1")
            expectation.fulfill()
        }
        XCTAssertTrue(requestConsolidator.requestInFlight)
        requestConsolidator.queue(request: request2) { response in
            print("testVar variable 2: \(response.config?.variables["testVar"]?.value as! String)")
            XCTAssertEqual(response.config?.variables["testVar"]?.value as! String, "thirdPage")
            print("Fulfill 2")
            expectation.fulfill()
        }
        requestConsolidator.queue(request: request3) { response in
            print("testVar variable 3: \(response.config?.variables["testVar"]?.value as! String)")
            XCTAssertEqual(response.config?.variables["testVar"]?.value as! String, "thirdPage")
            print("Fulfill 3")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertFalse(requestConsolidator.requestInFlight)
    }
}

extension RequestConsolidatorTests {
    class MockService: DevCycleServiceProtocol {
        func getConfig(user: DVCUser, enableEdgeDB: Bool, completion: @escaping ConfigCompletionHandler) {
            XCTAssert(true)
        }

        func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
            XCTAssert(true)
        }
        
        func saveEntity(user: DVCUser, completion: @escaping SaveEntityCompletionHandler) {
            XCTAssert(true)
        }
        
        func makeRequest(request: URLRequest, completion: @escaping CompletionHandler) {
            let randomDelay = Double.random(in: 0.2...1.0)
            let configData = """
            {
                "project": {
                    "_id": "id1",
                    "key": "default"
                },
                "environment": {
                    "_id": "id2",
                    "key": "development"
                },
                "features": {},
                "featureVariationMap": {},
                "knownVariableKeys": [],
                "variables": {
                    "testVar": {
                        "_id": "id",
                        "key": "testVar",
                        "value": "\(request.url!.pathComponents.last ?? "any_value")",
                        "type": "String"
                    }
                }
            }
            """.data(using: .utf8)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                completion((configData, nil, nil))
            }
        }
    }
}
