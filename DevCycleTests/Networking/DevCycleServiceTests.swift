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
        XCTAssert(url!.contains("envKey=my_env_key"))
        XCTAssert(url!.contains("user_id=my_user"))
    }
    
    func testCreateConfigURLRequestWithEdgeDB() throws {
        let url = getService().createConfigRequest(user: getTestUser(), enableEdgeDB: true).url?.absoluteString
        XCTAssert(url!.contains("https://sdk-api.devcycle.com/v1/mobileSDKConfig"))
        XCTAssert(url!.contains("envKey=my_env_key"))
        XCTAssert(url!.contains("user_id=my_user"))
        XCTAssert(url!.contains("enableEdgeDB=true"))
    }
    
    func testCreateEventURLRequest() throws {
        let url = getService().createEventsRequest().url?.absoluteString
        XCTAssert(url!.contains("https://events.devcycle.com/v1/events"))
        XCTAssertFalse(url!.contains("user_id=my_user"))
    }
    
    func testCreateSaveEntityRequest() throws {
        let url = getService().createSaveEntityRequest().url?.absoluteString
        XCTAssert(url!.contains("https://sdk-api.devcycle.com/v1/edgedb"))
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
        
        func save(user: DVCUser) {
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
        
        func setConfigUserId(user:DVCUser, userId: String?) {
            // TODO: update implementation for tests
        }
        
        func getConfigUserId(user: DVCUser) -> String? {
            return nil
        }
        
        func setConfigFetchDate(user:DVCUser, fetchDate: Int) {
            // TODO: update implementation for tests
        }
        
        func getConfigFetchDate(user: DVCUser) -> Int? {
            return nil
        }
        
        func saveConfig(user: DVCUser, configToSave: Data?) {
            self.saveConfigCalled = true
        }
        
        func getConfig(user: DVCUser) -> UserConfig? {
            return nil
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


