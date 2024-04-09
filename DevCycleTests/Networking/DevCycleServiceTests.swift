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
        let service = getService()
        let data = "{\"config\":\"key}".data(using: .utf8)
        let config = processConfig(data)
        XCTAssertNil(config)
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


