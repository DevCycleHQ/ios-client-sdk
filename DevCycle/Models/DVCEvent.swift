//
//  DVCEvent.swift
//  DevCycle
//
//

import Foundation

enum DVCEventTypes: String {
    case VariableDefaulted, VariableEvaluated
}

struct DVCAggregateEvents {
    var variableDefaulted: [String:DVCEvent]
    var variableEvaluated: [String:DVCEvent]
    
    init () {
        self.variableDefaulted = [:]
        self.variableEvaluated = [:]
    }
    
    mutating func track(variableKey: String, eventType: DVCEventTypes) {
        if (eventType == DVCEventTypes.VariableEvaluated) {
            if var variableEvaluatedEvent = self.variableEvaluated[variableKey] {
                variableEvaluatedEvent.value = variableEvaluatedEvent.value! + 1
            } else {
                self.variableEvaluated[variableKey] = DVCEvent(type: "variableEvaluated", target: variableKey, clientDate: nil, value: 1, metaData: nil)
            }
        } else {
            if var variableDefaultedEvent = self.variableDefaulted[variableKey] {
                variableDefaultedEvent.value = variableDefaultedEvent.value! + 1
            } else {
                self.variableDefaulted[variableKey] = DVCEvent(type: "variableDefaulted", target: variableKey, clientDate: nil, value: 1, metaData: nil)
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
