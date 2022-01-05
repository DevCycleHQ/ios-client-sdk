//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DevCycleServiceTests: XCTestCase {
    func testCreateConfigURLRequest() throws {
        let url = getService().createConfigRequest(user: getTestUser()).url?.absoluteString
        XCTAssert(url!.contains("https://sdk-api.devcycle.com/v1/mobileSDKConfig"))
        XCTAssert(url!.contains("envKey=my_env_key"))
        XCTAssert(url!.contains("user_id=my_user"))
    }
    
    func testCreateEventURLRequest() throws {
        let url = getService().createEventsRequest().url?.absoluteString
        XCTAssert(url!.contains("https://events.devcycle.com/v1/events"))
        XCTAssertFalse(url!.contains("user_id=my_user"))
    }
    
    func testProcessConfigReturnsNilIfMissingProperties() throws {
        let service = getService()
        let data = "{\"config\":\"key\"}".data(using: .utf8)
        let config = service.processConfig(data)
        XCTAssertNil(config)
    }
    
    func testProcessConfigReturnsNilIfBrokenJson() throws {
        let service = getService()
        let data = "{\"config\":\"key}".data(using: .utf8)
        let config = service.processConfig(data)
        XCTAssertNil(config)
    }
    
    func testServiceSavesConfigToCache() throws {
        let service = getService()
        let data = getConfigData()
        let config = service.processConfig(data)
        XCTAssertNotNil(config)
        XCTAssert((service.cacheService as! MockCacheService).saveConfigCalled)
    }
    
    func testServiceSavesUserToCache() throws {
        let service = getService()
        let data = getConfigData()
        
        let mockSession = URLSessionMock()
        mockSession.data = data
        service.session = mockSession
        let exp = expectation(description: "Saves user to cache")
        
        let user = try! DVCUser.builder().userId("dummy_user").build()
        service.getConfig(user: user) { config in
            XCTAssert((service.cacheService as! MockCacheService).saveUserCalled)
            exp.fulfill()
        }
        
        waitForExpectations(timeout:  2)
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
        
        func save(user: DVCUser, anonymous: Bool) {
            self.saveUserCalled = true
        }
        
        func save(config: Data) {
            self.saveConfigCalled = true
        }
    }

    func getService() -> DevCycleService {
        let user = getTestUser()
        let config = DVCConfig(environmentKey: "my_env_key", user: user)
        return DevCycleService(config: config, cacheService: MockCacheService())
    }
    
    func getTestUser() -> DVCUser {
        return try! DVCUser.builder()
            .userId("my_user")
            .build()
    }
    
    func getConfigData() -> Data {
        let bundle = Bundle(for: type(of: self))
        let fileUrl = bundle.url(forResource: "test_config", withExtension: "json")
        return try! Data(contentsOf: fileUrl!)
    }
}


