//
//  DVCEvent.swift
//  DevCycle
//
//

import Foundation

public struct DVCEvent {
    var type: String
    var target: String?
    var clientDate: Date?
    var value: Int?
    var metaData: [String: Any]?
    var user_id: String?
    var date: Date?
    var featureVars: [String: String]?
}
