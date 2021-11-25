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
        XCTAssert(user.isAnonymous)
        XCTAssert(user.platform == "iOS")
        XCTAssertNotNil(user.createdDate)
        XCTAssertNotNil(user.platformVersion)
        XCTAssertNotNil(user.deviceModel == "iPhone")
        XCTAssert(user.sdkType == "client")
        XCTAssertNotNil(user.sdkVersion)
    }

}
