//
//  DVCEvent.swift
//  DevCycle
//
//

import Foundation

public struct DVCEvent {
    var type: String
    var target: String?
    var date: Date?
    var value: Int?
    var metaData: [String: Any]?
}
