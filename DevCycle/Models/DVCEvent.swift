//
//  DVCEvent.swift
//  DevCycle
//
//

import Foundation

struct DVCEventTypes {
    var VariableDefaulted: [String:DVCEvent]
    var VariableEvaluated: [String:DVCEvent]
    
    init () {
        self.VariableDefaulted = [:]
        self.VariableEvaluated = [:]
    }
    
    mutating func track(variableKey: String, eventType: String) {
        if (eventType == "variableEvaluated") {
            if var variableEvaluatedEvent = self.VariableEvaluated[variableKey] {
                variableEvaluatedEvent.value = variableEvaluatedEvent.value! + 1
            } else {
                self.VariableEvaluated[variableKey] = DVCEvent(type: "variableEvaluated", target: variableKey, clientDate: nil, value: 1, metaData: nil)
            }
        } else {
            if var variableDefaultedEvent = self.VariableDefaulted[variableKey] {
                variableDefaultedEvent.value = variableDefaultedEvent.value! + 1
            } else {
                self.VariableDefaulted[variableKey] = DVCEvent(type: "variableDefaulted", target: variableKey, clientDate: nil, value: 1, metaData: nil)
            }
        }
    }
}

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
