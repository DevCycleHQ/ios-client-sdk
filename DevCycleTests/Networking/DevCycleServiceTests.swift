//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DevCycleServiceTests: XCTestCase {
    func testCreateConfigURLRequest() throws {
        let url = getService().createConfigRequest(user: getTestUser(), enableEdgeDB: false).url?.absoluteString
        XCTAssert(url!.contains("https://sdk-api.devcycle.com/v1/mobileSDKConfig"))
        XCTAssert(url!.contains("sdkKey=my_sdk_key"))
        XCTAssert(url!.contains("user_id=my_user"))
    }
    
    func testProxyConfigURL() throws {
        let options = DevCycleOptions.builder().apiProxyURL("localhost:4000").build()
        let service = getService(options)
        let url = service.createConfigRequest(user: getTestUser(), enableEdgeDB: false).url?.absoluteString
        let eventsUrl = service.createEventsRequest().url?.absoluteString
        
        XCTAssert(url!.contains("localhost:4000/v1/mobileSDKConfig"))
        XCTAssert(url!.contains("sdkKey=my_sdk_key"))
        XCTAssert(url!.contains("user_id=my_user"))
        XCTAssertFalse(eventsUrl!.contains("localhost:4000"))
    }
    
    func testCreateConfigURLRequestWithEdgeDB() throws {
        let url = getService().createConfigRequest(user: getTestUser(), enableEdgeDB: true).url?.absoluteString
        XCTAssert(url!.contains("https://sdk-api.devcycle.com/v1/mobileSDKConfig"))
        XCTAssert(url!.contains("sdkKey=my_sdk_key"))
        XCTAssert(url!.contains("user_id=my_user"))
        XCTAssert(url!.contains("enableEdgeDB=true"))
    }
    
    func testCreateEventURLRequest() throws {
        let url = getService().createEventsRequest().url?.absoluteString
        XCTAssert(url!.contains("https://events.devcycle.com/v1/events"))
        XCTAssertFalse(url!.contains("user_id=my_user"))
    }
    
    func testProxyEventUrl() throws {
        let options = DevCycleOptions.builder().eventsApiProxyURL("localhost:4000").build()
        let service = getService(options)
        let url = service.createEventsRequest().url?.absoluteString
        let apiUrl = service.createConfigRequest(user: getTestUser(), enableEdgeDB: false).url?.absoluteString
        
        XCTAssert(url!.contains("localhost:4000/v1/events"))
        XCTAssertFalse(apiUrl!.contains("localhost:4000"))
        XCTAssertFalse(url!.contains("user_id=my_user"))
    }
    
    func testCreateSaveEntityRequest() throws {
        let url = getService().createSaveEntityRequest().url?.absoluteString
        XCTAssert(url!.contains("https://sdk-api.devcycle.com/v1/edgedb"))
        XCTAssert(url!.contains("my_user"))
    }
    
    func testProxyEntityUrl() throws {
        let options = DevCycleOptions.builder().apiProxyURL("localhost:4000").build()
        let url = getService(options).createSaveEntityRequest().url?.absoluteString
        XCTAssert(url!.contains("localhost:4000/v1/edgedb"))
        XCTAssert(url!.contains("my_user"))
    }
    
    func testProcessConfigReturnsNilIfMissingProperties() throws {
        let data = "{\"config\":\"key\"}".data(using: .utf8)
        let config = processConfig(data)
        XCTAssertNil(config)
    }
    
    func testProcessConfigReturnsNilIfBrokenJson() throws {
        let data = "{\"config\":\"key}".data(using: .utf8)
        let config = processConfig(data)
        XCTAssertNil(config)
    }
    
    func testFlushingEvents() {
        let service = MockDevCycleService()
        let eventQueue = EventQueue()
        let user = try! DevCycleUser.builder().userId("user1").build()
        let expectation = XCTestExpectation(description: "10 Events are flushed in a single batch")
        
        // Generate 205 custom events and add them to the queue
        for i in 0..<10 {
            let event = try! DevCycleEvent.builder().type("event_\(i)").build()
            eventQueue.queue(event)
        }
        eventQueue.flush(service: service, user: user, callback: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(eventQueue.events.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(service.publishEventsCalled)
        XCTAssertEqual(service.makeRequestCallCount, 1, "makeRequest should have been called 1 time")
    }
    
    func testFlushingLargeNumberOfEvents() {
        let service = MockDevCycleService()
        let eventQueue = EventQueue()
        let user = try! DevCycleUser.builder().userId("user1").build()
        let expectation = XCTestExpectation(description: "205 Events are flushed in a single batch")
        
        // Generate 205 custom events and add them to the queue
        for i in 0..<205 {
            let event = try! DevCycleEvent.builder().type("event_\(i)").build()
            eventQueue.queue(event)
        }
        eventQueue.flush(service: service, user: user, callback: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(eventQueue.events.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(service.publishEventsCalled)
        XCTAssertEqual(service.makeRequestCallCount, 1, "makeRequest should have been called 1 times")
    }
}

extension DevCycleServiceTests {
    class MockCacheService: CacheServiceProtocol {
        var loadCalled = false
        var saveUserCalled = false
        var saveConfigCalled = false
        func load() -> Cache {
            self.loadCalled = true
            return Cache(config: nil, user: nil)
        }
        
        func save(user: DevCycleUser) {
            self.saveUserCalled = true
        }
        func setAnonUserId(anonUserId: String) {
            // TODO: update implementation for tests
        }
        func getAnonUserId() -> String? {
            return nil
        }
        func clearAnonUserId() {
            // TODO: update implementation for tests
        }
        
        func saveConfig(user: DevCycleUser, fetchDate: Int, configToSave: Data?) {
            self.saveConfigCalled = true
        }
        
        func getConfig(user: DevCycleUser, ttlMs: Int) -> UserConfig? {
            return nil
        }
    }

    class MockDevCycleService: DevCycleServiceProtocol {
        func getConfig(user: DevCycle.DevCycleUser, enableEdgeDB: Bool, extraParams: DevCycle.RequestParams?, completion: @escaping DevCycle.ConfigCompletionHandler) {
            // Empty Stub
        }
        
        func saveEntity(user: DevCycle.DevCycleUser, completion: @escaping DevCycle.SaveEntityCompletionHandler) {
            // Empty Stub
        }
        
        var publishEventsCalled = false
        var makeRequestCallCount = 0
        let testMaxBatchSize = 100
        var sdkKey = "my_sdk_key"
        
        func publishEvents(events: [DevCycleEvent], user: DevCycleUser, completion: @escaping PublishEventsCompletionHandler) {
            publishEventsCalled = true

            let userEncoder = JSONEncoder()
            userEncoder.dateEncodingStrategy = .iso8601
            guard let userId = user.userId, let userData = try? userEncoder.encode(user) else {
                return completion((nil, nil, ClientError.MissingUser))
            }
            
            let eventPayload = self.generateEventPayload(events, userId, nil)
            guard let userBody = try? JSONSerialization.jsonObject(with: userData, options: .fragmentsAllowed) else {
                return completion((nil, nil, ClientError.InvalidUser))
            }

            self.batchEventsPayload(events: eventPayload, user: userBody, completion: completion)
        }
        
        func makeRequest(request: URLRequest, completion: @escaping CompletionHandler) {
            self.makeRequestCallCount += 1
            
            // Mock implementation for makeRequest
            let mockData = "Successfully flushed \(self.testMaxBatchSize) events".data(using: .utf8)
            let mockResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
            completion((mockData, mockResponse, nil))
        }
        
        private func generateEventPayload(_ events: [DevCycleEvent], _ userId: String, _ featureVariables: [String:String]?) -> [[String:Any]] {
            var eventsJSON: [[String:Any]] = []
            let formatter = ISO8601DateFormatter()
            
            for event in events {
                if event.type == nil {
                    continue
                }
                let eventDate: Date = event.clientDate ?? Date()
                var eventToPost: [String: Any] = [
                    "type": event.type!,
                    "clientDate": formatter.string(from: eventDate),
                    "user_id": userId,
                    "featureVars": featureVariables ?? [:]
                ]

                if (event.target != nil) { eventToPost["target"] = event.target }
                if (event.value != nil) { eventToPost["value"] = event.value }
                if (event.metaData != nil) { eventToPost["metaData"] = event.metaData }
                if (event.type != "variableDefaulted" && event.type != "variableEvaluated") {
                    eventToPost["customType"] = event.type
                    eventToPost["type"] = "customEvent"
                }
                
                eventsJSON.append(eventToPost)
            }

            return eventsJSON
        }

        private func batchEventsPayload(events: [[String:Any]], user: Any, completion: @escaping PublishEventsCompletionHandler) {
            let url = URL(string: "http://test.com/v1/events")!
            var eventsRequest = URLRequest(url: url)
            eventsRequest.httpMethod = "POST"
            eventsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            eventsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            eventsRequest.addValue(self.sdkKey, forHTTPHeaderField: "Authorization")

            let requestBody: [String: Any] = [
                "events": events,
                "user": user
            ]

            let jsonBody = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            Log.debug("Post Events Payload: \(String(data: jsonBody!, encoding: .utf8) ?? "")")
            eventsRequest.httpBody = jsonBody

            self.makeRequest(request: eventsRequest) { data, response, error in
                if error != nil || data == nil {
                    return completion((data, response, error))
                }

                return completion((data, response, nil))
            }
        }
    }


    func getService(_ options: DevCycleOptions? = nil) -> DevCycleService {
        let user = getTestUser()
        let config = DVCConfig(sdkKey: "my_sdk_key", user: user)
        return DevCycleService(config: config, cacheService: MockCacheService(), options: options)
    }
    
    func getTestUser() -> DevCycleUser {
        return try! DevCycleUser.builder()
            .userId("my_user")
            .build()
    }
}


