//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DVCUserTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateUser() {
        let user = DVCUser()
        XCTAssert(user.platform == "iOS")
        XCTAssertNotNil(user.createdDate)
        XCTAssertNotNil(user.lastSeenDate)
        XCTAssertNotNil(user.platformVersion)
        XCTAssertNotNil(user.deviceModel == "iPhone")
        XCTAssert(user.sdkType == "client")
        XCTAssertNotNil(user.sdkVersion)
    }

    func testBuilderReturnsNilIfNoUserIdOrIsAnonymous() {
        let user = DVCUser.builder()
                    .build()
        XCTAssertNil(user)
    }
    
    func testBuilderReturnsUserIfUserIdSet() {
        let user = DVCUser.builder().userId("my_user").build()!
        XCTAssertNotNil(user)
        XCTAssert(user.userId == "my_user")
        XCTAssert(!user.isAnonymous!)
    }
    
    func testBuilderReturnsUserIfIsAnonymousSet() {
        let user = DVCUser.builder().isAnonymous(true).build()!
        XCTAssertNotNil(user)
        XCTAssert(user.isAnonymous!)
        XCTAssert(UUID(uuidString: user.userId!) != nil)
    }
    
    func testToStringOnlyOutputsNonNilProperties() {
        let userString = getTestUser().toString()
        XCTAssertNotNil(userString)
        XCTAssert(userString.contains("user_id=my_user"))
        XCTAssert(userString.contains("isAnonymous=false"))
        XCTAssertFalse(userString.contains("country"))
    }
    
    func testToStringOuputsDatesAndMapCorrectly() {
        let userString = getTestUser().toString()
        let params = userString.split(separator: "&")
        for param in params {
            if (param.contains("createdDate")) {
                let date = param.split(separator: "=").last!
                XCTAssertNoThrow(Int(date), "")
            }
        }
        XCTAssert(userString.contains("customData={\"custom\":\"key\"}"))
    }
}

extension DVCUserTest {
    func getTestUser() -> DVCUser {
        return DVCUser.builder()
            .userId("my_user")
            .isAnonymous(false)
            .customData(["custom": "key"])
            .build()!
    }
}
