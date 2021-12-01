//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DevCycleServiceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateGetURLRequest() throws {
        let url = getService().createConfigRequest(user: getTestUser()).url?.absoluteString
        XCTAssert(url!.contains("envKey=my_env_key"))
        XCTAssert(url!.contains("user_id=my_user"))
    }
    
    func testProcessConfig() throws {
        let service = getService()
        let data = "{\"config\":\"key\"}".data(using: .utf8)
        let config = service.processConfig(data)
        XCTAssertNotNil(config)
    }
}

extension DevCycleServiceTests {
    func getService() -> DevCycleService {
        let user = getTestUser()
        let config = DVCConfig(environmentKey: "my_env_key", user: user)
        return DevCycleService(config: config)
    }
    
    func getTestUser() -> DVCUser {
        return DVCUser.builder()
            .userId("my_user")
            .build()!
    }
}
