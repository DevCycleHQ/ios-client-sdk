//
//  DVCConfigTests.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

final class DVCConfigTests: XCTestCase {
    
    var mockUser: DevCycleUser!
    
    override func setUp() {
        super.setUp()
        mockUser = try! DevCycleUser.builder()
            .userId("test-user")
            .isAnonymous(false)
            .build()
    }
    
    override func tearDown() {
        mockUser = nil
        super.tearDown()
    }

    func getMockUserConfig(config: String = "test_config_eval_reason") throws -> UserConfig {
        let data = getConfigData(name: config)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
        return try UserConfig(from: dictionary)
    }
    
    func testConcurrentConfigAccess() throws {
        let testConfig = DVCConfig(sdkKey: "test-sdk-key", user: mockUser)
        
        let expectation = XCTestExpectation(description: "Concurrent config access completed")
        expectation.expectedFulfillmentCount = 100 // 50 reads + 50 writes
        
        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        // Test concurrent reads
        for _ in 0..<50 {
            concurrentQueue.async {
                let _ = testConfig.getUserConfig()
                expectation.fulfill()
            }
        }
        
        let evalConfig = try self.getMockUserConfig(config: "test_config_eval_reason")
        
        // Test concurrent writes
        for _ in 0..<50 {
            concurrentQueue.async {
                testConfig.setUserConfig(config: evalConfig)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify the final state is consistent
        let finalConfig = testConfig.getUserConfig()
        XCTAssertNotNil(finalConfig)
    }
    
    func testConcurrentConfigAccessWithVariables() throws {
        let testConfig = DVCConfig(sdkKey: "test-sdk-key", user: mockUser)
        let mockUserConfig = try getMockUserConfig()
        testConfig.setUserConfig(config: mockUserConfig)
        
        let expectation = XCTestExpectation(description: "Concurrent variable access completed")
        expectation.expectedFulfillmentCount = 200 // 100 reads + 100 writes
        
        let concurrentQueue = DispatchQueue(label: "test.concurrent.variables", attributes: .concurrent)
        
        // Test concurrent reads of variables
        for _ in 0..<100 {
            concurrentQueue.async {
                let variables = testConfig.getUserConfig()?.variables
                XCTAssertNotNil(variables)
                expectation.fulfill()
            }
        }
        let evalConfig = try self.getMockUserConfig(config: "test_config_eval_reason")

        // Test concurrent writes with new configs
        for _ in 0..<100 {
            concurrentQueue.async {
                testConfig.setUserConfig(config: evalConfig)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify final state
        let finalConfig = testConfig.getUserConfig()
        XCTAssertNotNil(finalConfig)
        XCTAssertNotNil(finalConfig?.variables)
    }
    
    func testRapidConfigUpdates() throws {
        let testConfig = DVCConfig(sdkKey: "test-sdk-key", user: mockUser)
        
        let expectation = XCTestExpectation(description: "Rapid config updates completed")
        expectation.expectedFulfillmentCount = 1000
        
        let concurrentQueue = DispatchQueue(label: "test.rapid", attributes: .concurrent)
        let evalConfig = try self.getMockUserConfig(config: "test_config_eval_reason")

        // Rapidly update config from multiple threads
        for _ in 0..<1000 {
            concurrentQueue.async {
                testConfig.setUserConfig(config: evalConfig)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify no crashes occurred
        let finalConfig = testConfig.getUserConfig()
        XCTAssertNotNil(finalConfig)
    }
    
    func testConfigAccessDuringUpdates() throws {
        
        let testConfig = DVCConfig(sdkKey: "test-sdk-key", user: mockUser)
        testConfig.setUserConfig(config: try self.getMockUserConfig())
        
        let expectation = XCTestExpectation(description: "Config access during updates completed")
        expectation.expectedFulfillmentCount = 500 // 250 updates + 250 reads
        
        let updateQueue = DispatchQueue(label: "test.updates", attributes: .concurrent)
        let readQueue = DispatchQueue(label: "test.reads", attributes: .concurrent)
        
        let evalConfig = try self.getMockUserConfig(config: "test_config_eval_reason")
        
        // Continuously update config
        for _ in 0..<250 {
            updateQueue.async {
                testConfig.setUserConfig(config: evalConfig)
                expectation.fulfill()
            }
        }
        
        // Continuously read config while updates are happening
        for _ in 0..<250 {
            readQueue.async {
                let config = testConfig.getUserConfig()
                _ = config?.variables
                _ = config?.features
                XCTAssertNotNil(config)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify final state
        let finalConfig = testConfig.getUserConfig()
        XCTAssertNotNil(finalConfig)
    }
    
    func testSetConfigNil() throws {
        let testNilConfig = DVCConfig(sdkKey: "test-sdk-key", user: mockUser)
        testNilConfig.setUserConfig(config: try self.getMockUserConfig())
        
        let expectation = XCTestExpectation(description: "Config access during setting config to nil completed")
        expectation.expectedFulfillmentCount = 500 // 250 updates + 250 reads
        
        let updateQueue = DispatchQueue(label: "test.updates", attributes: .concurrent)
        let readQueue = DispatchQueue(label: "test.reads", attributes: .concurrent)
        
        let evalConfig = try self.getMockUserConfig(config: "test_config_eval_reason")
        
        // Continuously update config
        for i in 0..<250 {
            updateQueue.async {
                testNilConfig.setUserConfig(config: i % 2 == 0 ? evalConfig : nil)
                expectation.fulfill()
            }
        }
        
        // Continuously read config while updates are happening
        for _ in 0..<250 {
            readQueue.async {
                let config = testNilConfig.getUserConfig()
                _ = config?.variables
                _ = config?.features
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
