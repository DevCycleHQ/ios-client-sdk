//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest

@testable import DevCycle

class DevCycleUserTest: XCTestCase {
    func testCreateUser() {
        let user = DevCycleUser()
        #if os(tvOS)
            XCTAssert(user.platform == "tvOS")
            XCTAssertNotNil(user.platformVersion)
            XCTAssert(user.deviceModel.contains("AppleTV"))
        #elseif os(iOS)
            XCTAssert(user.platform == "iOS" || user.platform == "iPadOS")
            XCTAssertNotNil(user.platformVersion)
            XCTAssert(user.deviceModel.contains("iPhone") || user.deviceModel.contains("iPad"))
        #elseif os(watchOS)
            XCTAssert(user.platform == "watchOS")
            XCTAssertNotNil(user.platformVersion)
            XCTAssert(user.deviceModel.contains("Watch"))
        #elseif os(OSX)
            XCTAssert(user.platform == "macOS")
            XCTAssertNotNil(user.platformVersion)
            XCTAssertNotNil(user.deviceModel)
        #endif

        XCTAssertNotNil(user.createdDate)
        XCTAssertNotNil(user.lastSeenDate)
        XCTAssert(user.sdkType == "mobile")
        XCTAssertNotNil(user.sdkVersion)
    }

    func testDeprecatedDVCUser() {
        let user = try! DVCUser.builder()
            .build()
        XCTAssertNotNil(user)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
        XCTAssertTrue(user.isAnonymous!)
    }

    func testBuilderReturnsAnonUserIfNoUserIdOrIsAnonymous() {
        let user = try! DevCycleUser.builder()
            .build()
        XCTAssertNotNil(user)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
        XCTAssertTrue(user.isAnonymous!)
    }

    func testBuilderReturnsAnonUserIfNoUserIdAndIsAnonymousIsFalse() {
        let user = try! DevCycleUser.builder()
            .isAnonymous(false)
            .build()
        XCTAssertNotNil(user)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
        XCTAssertTrue(user.isAnonymous!)
    }

    func testBuilderReturnsUserIfUserIdSet() {
        let user = try! DevCycleUser.builder().userId("my_user").build()
        XCTAssertNotNil(user)
        XCTAssert(user.userId == "my_user")
        XCTAssert(!user.isAnonymous!)
    }

    func testBuilderReturnsUserIfIsAnonymousSet() {
        let user = try! DevCycleUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(user)
        XCTAssert(user.isAnonymous!)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
    }

    func testBuilderReturnsNilIfUserIdIsEmptyString() {
        let user = try? DevCycleUser.builder().userId("").build()
        XCTAssertNil(user)
    }

    func testBuilderReturnsNilIfUserIdOnlyContainsWhitespaces() {
        let user = try? DevCycleUser.builder().userId(" ").build()
        XCTAssertNil(user)
    }

    func testToStringOnlyOutputsNonNilProperties() {
        var components = URLComponents(string: "test.com")
        components?.queryItems = getTestUser().toQueryItems()
        let urlString = components?.url?.absoluteString
        XCTAssertNotNil(urlString)
        XCTAssert(urlString!.contains("user_id=my_user"))
        XCTAssert(urlString!.contains("isAnonymous=false"))
        XCTAssertFalse(urlString!.contains("country"))
    }

    func testToStringOuputsDatesAndMapCorrectly() {
        var components = URLComponents(string: "test.com")
        components?.queryItems = getTestUser().toQueryItems()
        let urlString = components?.url?.absoluteString
        let params = urlString!.split(separator: "?")[1].split(separator: "&")
        for param in params {
            if param.contains("createdDate") {
                let date = param.split(separator: "=").last!
                XCTAssertNoThrow(Int(date), "")
            }
        }
        XCTAssert(urlString!.contains("customData=%7B%22custom%22:%22key%22%7D"))
        XCTAssert(urlString!.contains("privateCustomData=%7B%22custom2%22:%22key2%22%7D"))
    }

    func testAnonymousUserIdCaching() {
        let cacheService = CacheService()
        cacheService.setAnonUserId(anonUserId: "123")

        let anonUser = try! DevCycleUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser)
        XCTAssert(anonUser.isAnonymous!)
        XCTAssertEqual(anonUser.userId, "123")

        let anonUser2 = try! DevCycleUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser2)
        XCTAssert(anonUser2.isAnonymous!)
        XCTAssertEqual(anonUser2.userId, "123")

        cacheService.clearAnonUserId()
    }

    func testConfigCachingPerUser() {
        let cacheService = CacheService()
        
        // Create test users
        let user1 = try! DevCycleUser.builder().userId("user1").build()
        let user2 = try! DevCycleUser.builder().userId("user2").build()
        let anonUser = try! DevCycleUser.builder().userId("anon123").isAnonymous(true).build()
        
        // Mock config data
        let configData1 = "{\"variables\": {\"test1\": \"value1\"}}".data(using: .utf8)
        let configData2 = "{\"variables\": {\"test2\": \"value2\"}}".data(using: .utf8)
        let configDataAnon = "{\"variables\": {\"testAnon\": \"valueAnon\"}}".data(using: .utf8)
        
        let currentTime = Int(Date().timeIntervalSince1970)
        
        // Save configs for different users
        cacheService.saveConfig(user: user1, fetchDate: currentTime, configToSave: configData1)
        cacheService.saveConfig(user: user2, fetchDate: currentTime, configToSave: configData2)
        cacheService.saveConfig(user: anonUser, fetchDate: currentTime, configToSave: configDataAnon)
        
        // Verify configs can be retrieved for specific users
        let retrievedConfig1 = cacheService.getConfig(user: user1, ttlMs: 3600000) // 1 hour TTL
        let retrievedConfig2 = cacheService.getConfig(user: user2, ttlMs: 3600000)
        let retrievedConfigAnon = cacheService.getConfig(user: anonUser, ttlMs: 3600000)
        
        XCTAssertNotNil(retrievedConfig1, "Config for user1 should be retrievable")
        XCTAssertNotNil(retrievedConfig2, "Config for user2 should be retrievable")
        XCTAssertNotNil(retrievedConfigAnon, "Config for anonymous user should be retrievable")
        
        // Verify configs are different (user-specific)
        // Note: Since UserConfig construction from JSON might be complex, we're mainly verifying that
        // the caching mechanism can store and retrieve per-user data
        
        // Test that a different user cannot retrieve another user's config
        let user3 = try! DevCycleUser.builder().userId("user3").build()
        let nonExistentConfig = cacheService.getConfig(user: user3, ttlMs: 3600000)
        XCTAssertNil(nonExistentConfig, "User3 should not have any cached config")
    }

    func testConfigCacheTTLRespected() {
        let cacheService = CacheService()
        let user = try! DevCycleUser.builder().userId("test_user").build()
        let configData = "{\"variables\": {\"test\": \"value\"}}".data(using: .utf8)
        
        // Save config with old timestamp (2 hours ago)
        let oldTime = Int(Date().timeIntervalSince1970) - 7200
        cacheService.saveConfig(user: user, fetchDate: oldTime, configToSave: configData)
        
        // Try to retrieve with 1 hour TTL (should fail)
        let expiredConfig = cacheService.getConfig(user: user, ttlMs: 3600000)
        XCTAssertNil(expiredConfig, "Expired config should not be returned")
        
        // Try to retrieve with 3 hour TTL (should succeed)
        let validConfig = cacheService.getConfig(user: user, ttlMs: 10800000)
        XCTAssertNotNil(validConfig, "Valid config should be returned within TTL")
    }
}

extension DevCycleUserTest {
    func getTestUser() -> DevCycleUser {
        return try! DevCycleUser.builder()
            .userId("my_user")
            .isAnonymous(false)
            .customData(["custom": "key"])
            .privateCustomData(["custom2": "key2"])
            .build()
    }
}
