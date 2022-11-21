//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DVCUserTest: XCTestCase {
    func testCreateUser() {
        let user = DVCUser()
        XCTAssert(user.platform == "iOS")
        XCTAssertNotNil(user.createdDate)
        XCTAssertNotNil(user.lastSeenDate)
        XCTAssertNotNil(user.platformVersion)
        XCTAssertNotNil(user.deviceModel == "iPhone")
        XCTAssert(user.sdkType == "mobile")
        XCTAssertNotNil(user.sdkVersion)
    }

    func testBuilderReturnsAnonUserIfNoUserIdOrIsAnonymous() {
        let user = try! DVCUser.builder()
                    .build()
        XCTAssertNotNil(user)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
        XCTAssertTrue(user.isAnonymous!)
    }
    
    func testBuilderReturnsAnonUserIfNoUserIdAndIsAnonymousIsFalse() {
        let user = try! DVCUser.builder()
                    .isAnonymous(false)
                    .build()
        XCTAssertNotNil(user)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
        XCTAssertTrue(user.isAnonymous!)
    }
    
    func testBuilderReturnsUserIfUserIdSet() {
        let user = try! DVCUser.builder().userId("my_user").build()
        XCTAssertNotNil(user)
        XCTAssert(user.userId == "my_user")
        XCTAssert(!user.isAnonymous!)
    }
    
    func testBuilderReturnsUserIfIsAnonymousSet() {
        let user = try! DVCUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(user)
        XCTAssert(user.isAnonymous!)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
    }
    
    func testBuilderReturnsNilIfUserIdIsEmptyString() {
        let user = try? DVCUser.builder().userId("").build()
        XCTAssertNil(user)
    }
    
    func testBuilderReturnsNilIfUserIdOnlyContainsWhitespaces() {
        let user = try? DVCUser.builder().userId(" ").build()
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
            if (param.contains("createdDate")) {
                let date = param.split(separator: "=").last!
                XCTAssertNoThrow(Int(date), "")
            }
        }
        XCTAssert(urlString!.contains("customData=%7B%22custom%22:%22key%22%7D"))
        XCTAssert(urlString!.contains("privateCustomData=%7B%22custom2%22:%22key2%22%7D"))
    }
    
    func testAnonymousUserIdCaching() {
        let anonUser = try! DVCUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser)
        XCTAssert(anonUser.isAnonymous!)
        XCTAssert(UUID(uuidString: anonUser.userId!) != nil)
        
        let anonUser2 = try! DVCUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser2)
        XCTAssert(anonUser2.isAnonymous!)
        XCTAssertEqual(anonUser2.userId, anonUser.userId)
    }
}

extension DVCUserTest {
    func getTestUser() -> DVCUser {
        return try! DVCUser.builder()
            .userId("my_user")
            .isAnonymous(false)
            .customData(["custom": "key"])
            .privateCustomData(["custom2": "key2"])
            .build()
    }
}
