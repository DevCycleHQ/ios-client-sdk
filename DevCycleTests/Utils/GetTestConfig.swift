//
//  GetTestConfig.swift
//  DevCycleTests
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation
import XCTest

func getConfigData(name: String, withExtension: String = "json") -> Data {
    #if SWIFT_PACKAGE
        let bundle = Bundle.module
    #else
        let bundle = Bundle(for: DevCycleClientTest.self)
    #endif
    guard let fileUrl = bundle.url(forResource: name, withExtension: withExtension) else {
        XCTFail("Missing test resource: \(name).\(withExtension)")
        return Data()
    }
    let data = try! Data(contentsOf: fileUrl)
    return data
}
