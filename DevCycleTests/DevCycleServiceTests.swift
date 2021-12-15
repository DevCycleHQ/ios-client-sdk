//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DevCycleServiceTests: XCTestCase {
    func testCreateGetURLRequest() throws {
        let url = getService().createConfigRequest(user: getTestUser()).url?.absoluteString
        XCTAssert(url!.contains("envKey=my_env_key"))
        XCTAssert(url!.contains("user_id=my_user"))
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
        let bundle = Bundle(for: type(of: self))
        let fileUrl = bundle.url(forResource: "test_config", withExtension: "json")
        let data = try! Data(contentsOf: fileUrl!)
        let config = service.processConfig(data)
        XCTAssertNotNil(config)
        XCTAssert((service.cacheService as! MockCacheService).saveConfigCalled)
    }
    
    func testServiceSavesUserToCache() throws {
        let service = getService()
        let data = "{\"config\":\"key}".data(using: .utf8)
        let config = service.processConfig(data)
        service.getConfig { config in
            //
        }
        XCTAssertNil(config)
        XCTAssert((service.cacheService as! MockCacheService).saveUserCalled)
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
        
        func save(user: DVCUser) {
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
}
