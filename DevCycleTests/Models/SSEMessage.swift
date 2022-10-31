//
//  SSEMessage.swift
//  DevCycleTests
//

import XCTest
@testable import DevCycle;

class SSEMessageTests: XCTestCase {
    func testShouldInitFromJson() throws {
        let jsonData = """
        {
            \"id\":\"test_id\",
            \"timestamp\":123,
            \"channel\":\"dvc_mobile_test\",
            \"data\":\"{\\\"etag\\\":\\\"\\\\\\\"123abc\\\\\\\"\\\",\\\"lastModified\\\":123}\",
            \"name\":\"change\"
        }
        """.data(using: .utf8)

        let dictionary = try JSONSerialization.jsonObject(with: jsonData!) as! [String: Any]
        let sseMessage = try SSEMessage(from: dictionary)
        XCTAssertNotNil(sseMessage.data)
        XCTAssertNotNil(sseMessage.data.etag)
        XCTAssertNotNil(sseMessage.data.lastModified)
    }

    func testShouldThrowInitErrorWhenDataFieldIsMissing() throws {
        let jsonData = """
        {
            \"id\":\"test_id\",
            \"timestamp\":123,
            \"channel\":\"dvc_mobile_test\",
            \"name\":\"change\"
        }
        """.data(using: .utf8)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData!) as! [String: Any]
        XCTAssertThrowsError(try SSEMessage(from: dictionary)) { error in
            XCTAssertEqual(error as! SSEMessage.SSEMessageError, SSEMessage.SSEMessageError.initError("No data field in SSE JSON"))
        }
    }

    func testShouldThrowErrorWhenDataFieldIsUnparsable() throws {
        let jsonData = """
        {
            \"id\":\"test_id\",
            \"timestamp\":123,
            \"channel\":\"dvc_mobile_test\",
            \"data\":\"{\\\"etag\\\":123abc\\\\\\\",\\\"lastModified\\\":123}\",
            \"name\":\"change\"
        }
        """.data(using: .utf8)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData!) as! [String: Any]
        XCTAssertThrowsError(try SSEMessage(from: dictionary)) { error in
            XCTAssertEqual(error as! SSEMessage.SSEMessageError, SSEMessage.SSEMessageError.initError("Failed to parse data field in SSE message"))
        }
    }
}
