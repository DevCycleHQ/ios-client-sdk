//
//  GetTestConfig.swift
//  DevCycleTests
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

func getConfigData(name: String, withExtension: String = "json") -> Data {
    let bundle = Bundle(for: DVCClientTest.self)
    let fileUrl = bundle.url(forResource: name, withExtension: withExtension)
    let data = try! Data(contentsOf: fileUrl!)
    return data
}
