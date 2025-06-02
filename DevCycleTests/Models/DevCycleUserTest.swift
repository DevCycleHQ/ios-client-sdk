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

        // Create valid UserConfig JSON structures
        let configJson1 = createConfigJson(
            projectId: "project1", environmentId: "env1", variableKey: "test1", variableId: "var1",
            variableValue: "value1")
        let configJson2 = createConfigJson(
            projectId: "project2", environmentId: "env2", variableKey: "test2", variableId: "var2",
            variableValue: "value2")
        let configJsonAnon = createConfigJson(
            projectId: "projectAnon", environmentId: "envAnon", variableKey: "testAnon",
            variableId: "varAnon", variableValue: "valueAnon")

        let configData1 = configJson1.data(using: .utf8)
        let configData2 = configJson2.data(using: .utf8)
        let configDataAnon = configJsonAnon.data(using: .utf8)

        let currentTime = Int(Date().timeIntervalSince1970)

        // Save configs for different users
        cacheService.saveConfig(user: user1, fetchDate: currentTime, configToSave: configData1)
        cacheService.saveConfig(user: user2, fetchDate: currentTime, configToSave: configData2)
        cacheService.saveConfig(
            user: anonUser, fetchDate: currentTime, configToSave: configDataAnon)

        // Verify configs can be retrieved for specific users
        let retrievedConfig1 = cacheService.getConfig(user: user1, ttlMs: 3_600_000)  // 1 hour TTL
        let retrievedConfig2 = cacheService.getConfig(user: user2, ttlMs: 3_600_000)
        let retrievedConfigAnon = cacheService.getConfig(user: anonUser, ttlMs: 3_600_000)

        XCTAssertNotNil(retrievedConfig1, "Config for user1 should be retrievable")
        XCTAssertNotNil(retrievedConfig2, "Config for user2 should be retrievable")
        XCTAssertNotNil(retrievedConfigAnon, "Config for anonymous user should be retrievable")

        // Verify configs contain the correct user-specific data by checking project._id
        XCTAssertEqual(
            retrievedConfig1?.project._id, "project1", "User1 should get their specific config")
        XCTAssertEqual(
            retrievedConfig2?.project._id, "project2", "User2 should get their specific config")
        XCTAssertEqual(
            retrievedConfigAnon?.project._id, "projectAnon",
            "Anonymous user should get their specific config")

        // Test that a different user cannot retrieve another user's config
        let user3 = try! DevCycleUser.builder().userId("user3").build()
        let nonExistentConfig = cacheService.getConfig(user: user3, ttlMs: 3_600_000)
        XCTAssertNil(nonExistentConfig, "User3 should not have any cached config")
    }

    func testConfigCacheTTLRespected() {
        let cacheService = CacheService()
        let user = try! DevCycleUser.builder().userId("test_user").build()

        let configJson = createConfigJson(
            projectId: "project1", environmentId: "env1", variableKey: "test", variableId: "var1",
            variableValue: "value")
        let configData = configJson.data(using: .utf8)

        // Save config with old timestamp (2 hours ago)
        let oldTime = Int(Date().timeIntervalSince1970) - 7200
        cacheService.saveConfig(user: user, fetchDate: oldTime, configToSave: configData)

        // Try to retrieve with 1 hour TTL (should fail)
        let expiredConfig = cacheService.getConfig(user: user, ttlMs: 3_600_000)
        XCTAssertNil(expiredConfig, "Expired config should not be returned")

        // Try to retrieve with 3 hour TTL (should succeed)
        let validConfig = cacheService.getConfig(user: user, ttlMs: 10_800_000)
        XCTAssertNotNil(validConfig, "Valid config should be returned within TTL")
    }

    func testLegacyCacheMigration() {
        let cacheService = CacheService()
        let defaults = UserDefaults.standard

        let identifiedUserId = "identified_user_123"
        let anonymousUserId = "anon_user_456"
        let configData = "{\"variables\": {\"test\": \"value\"}}".data(using: .utf8)
        let fetchDate = Int(Date().timeIntervalSince1970)

        defaults.set(configData, forKey: "IDENTIFIED_CONFIG")
        defaults.set(identifiedUserId, forKey: "IDENTIFIED_CONFIG.USER_ID")
        defaults.set(fetchDate, forKey: "IDENTIFIED_CONFIG.FETCH_DATE")

        defaults.set(configData, forKey: "ANONYMOUS_CONFIG")
        defaults.set(anonymousUserId, forKey: "ANONYMOUS_CONFIG.USER_ID")
        defaults.set(fetchDate, forKey: "ANONYMOUS_CONFIG.FETCH_DATE")

        cacheService.migrateLegacyCache()

        XCTAssertNil(
            defaults.object(forKey: "IDENTIFIED_CONFIG"),
            "Legacy identified config should be removed")
        XCTAssertNil(
            defaults.string(forKey: "IDENTIFIED_CONFIG.USER_ID"),
            "Legacy identified user ID should be removed")
        XCTAssertNil(
            defaults.object(forKey: "IDENTIFIED_CONFIG.FETCH_DATE"),
            "Legacy identified fetch date should be removed")

        XCTAssertNil(
            defaults.object(forKey: "ANONYMOUS_CONFIG"),
            "Legacy anonymous config should be removed")
        XCTAssertNil(
            defaults.string(forKey: "ANONYMOUS_CONFIG.USER_ID"),
            "Legacy anonymous user ID should be removed")
        XCTAssertNil(
            defaults.object(forKey: "ANONYMOUS_CONFIG.FETCH_DATE"),
            "Legacy anonymous fetch date should be removed")

        XCTAssertEqual(
            defaults.object(forKey: "IDENTIFIED_CONFIG_\(identifiedUserId)") as? Data,
            configData,
            "New identified config data should match original")
        XCTAssertEqual(
            defaults.string(forKey: "IDENTIFIED_CONFIG_\(identifiedUserId).USER_ID"),
            identifiedUserId,
            "New identified user ID should match")
        XCTAssertEqual(
            defaults.integer(forKey: "IDENTIFIED_CONFIG_\(identifiedUserId).FETCH_DATE"),
            fetchDate,
            "New identified fetch date should match")

        XCTAssertEqual(
            defaults.object(forKey: "ANONYMOUS_CONFIG_\(anonymousUserId)") as? Data,
            configData,
            "New anonymous config data should match original")
        XCTAssertEqual(
            defaults.string(forKey: "ANONYMOUS_CONFIG_\(anonymousUserId).USER_ID"),
            anonymousUserId,
            "New anonymous user ID should match")
        XCTAssertEqual(
            defaults.integer(forKey: "ANONYMOUS_CONFIG_\(anonymousUserId).FETCH_DATE"),
            fetchDate,
            "New anonymous fetch date should match")

        defaults.removeObject(forKey: "IDENTIFIED_CONFIG_\(identifiedUserId)")
        defaults.removeObject(forKey: "IDENTIFIED_CONFIG_\(identifiedUserId).USER_ID")
        defaults.removeObject(forKey: "IDENTIFIED_CONFIG_\(identifiedUserId).FETCH_DATE")
        defaults.removeObject(forKey: "ANONYMOUS_CONFIG_\(anonymousUserId)")
        defaults.removeObject(forKey: "ANONYMOUS_CONFIG_\(anonymousUserId).USER_ID")
        defaults.removeObject(forKey: "ANONYMOUS_CONFIG_\(anonymousUserId).FETCH_DATE")
    }

    func testLegacyCacheMigrationSkipsWhenNoData() {
        let cacheService = CacheService()

        cacheService.migrateLegacyCache()

        let defaults = UserDefaults.standard
        XCTAssertNil(defaults.object(forKey: "IDENTIFIED_CONFIG"), "No legacy config should exist")
        XCTAssertNil(defaults.object(forKey: "ANONYMOUS_CONFIG"), "No legacy config should exist")
    }

    func testLegacyCacheMigrationCleansUpWhenNewCacheExists() {
        let cacheService = CacheService()
        let defaults = UserDefaults.standard

        let userId = "test_user_123"
        let legacyConfigData = "{\"variables\": {\"legacy\": \"oldValue\"}}".data(using: .utf8)
        let newConfigData = "{\"variables\": {\"new\": \"newValue\"}}".data(using: .utf8)
        let legacyFetchDate = Int(Date().timeIntervalSince1970) - 3600  // 1 hour ago
        let newFetchDate = Int(Date().timeIntervalSince1970)  // now

        defaults.set(legacyConfigData, forKey: "IDENTIFIED_CONFIG")
        defaults.set(userId, forKey: "IDENTIFIED_CONFIG.USER_ID")
        defaults.set(legacyFetchDate, forKey: "IDENTIFIED_CONFIG.FETCH_DATE")

        defaults.set(newConfigData, forKey: "IDENTIFIED_CONFIG_\(userId)")
        defaults.set(userId, forKey: "IDENTIFIED_CONFIG_\(userId).USER_ID")
        defaults.set(newFetchDate, forKey: "IDENTIFIED_CONFIG_\(userId).FETCH_DATE")

        cacheService.migrateLegacyCache()

        XCTAssertNil(
            defaults.object(forKey: "IDENTIFIED_CONFIG"),
            "Legacy config should be removed when new cache exists")
        XCTAssertNil(
            defaults.string(forKey: "IDENTIFIED_CONFIG.USER_ID"),
            "Legacy user ID should be removed when new cache exists")
        XCTAssertNil(
            defaults.object(forKey: "IDENTIFIED_CONFIG.FETCH_DATE"),
            "Legacy fetch date should be removed when new cache exists")

        XCTAssertEqual(
            defaults.object(forKey: "IDENTIFIED_CONFIG_\(userId)") as? Data,
            newConfigData,
            "New config data should remain unchanged")
        XCTAssertEqual(
            defaults.string(forKey: "IDENTIFIED_CONFIG_\(userId).USER_ID"),
            userId,
            "New user ID should remain unchanged")
        XCTAssertEqual(
            defaults.integer(forKey: "IDENTIFIED_CONFIG_\(userId).FETCH_DATE"),
            newFetchDate,
            "New fetch date should remain unchanged")

        defaults.removeObject(forKey: "IDENTIFIED_CONFIG_\(userId)")
        defaults.removeObject(forKey: "IDENTIFIED_CONFIG_\(userId).USER_ID")
        defaults.removeObject(forKey: "IDENTIFIED_CONFIG_\(userId).FETCH_DATE")
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

    func createConfigJson(
        projectId: String, environmentId: String, variableKey: String, variableId: String,
        variableValue: String
    ) -> String {
        return """
            {
                "project": {
                    "_id": "\(projectId)",
                    "key": "test-project",
                    "settings": {
                        "edgeDB": {
                            "enabled": false
                        }
                    }
                },
                "environment": {
                    "_id": "\(environmentId)",
                    "key": "development"
                },
                "features": {},
                "featureVariationMap": {},
                "variables": {
                    "\(variableKey)": {
                        "_id": "\(variableId)",
                        "key": "\(variableKey)",
                        "type": "String",
                        "value": "\(variableValue)"
                    }
                }
            }
            """
    }
}
