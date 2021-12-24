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
    
    public init (type: String, target: String?, clientDate: Date?, value: Int?, metaData: [String: Any]?) {
        self.type =  type
        self.target = target
        self.clientDate = clientDate
        self.value = value
        self.metaData = metaData
    }
}
