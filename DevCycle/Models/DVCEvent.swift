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
        if (target != nil) {self.target = target}
        if (clientDate != nil) {self.clientDate = clientDate}
        if (value != nil) {self.value = value}
        if (metaData != nil) {self.metaData = metaData}
    }
}
