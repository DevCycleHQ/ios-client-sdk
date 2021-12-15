//
//  DVCEvent.swift
//  DevCycle
//
//  Created by Kaushal Kapasi on 2021-12-14.
//

import Foundation

public struct DVCEvent {
    var type: String
    var target: String?
    var date: Int?
    var value: Int?
    var metaData: [String: Any]?
}
