//
//  DVCEvent.swift
//  DevCycle
//
//

import Foundation

enum EventError: Error {
    case MissingEventType
}

public class DVCEvent {
    var type: String?
    var target: String?
    var clientDate: Date?
    var value: Int?
    var metaData: [String: Any]?
    
    init (type: String?, target: String?, clientDate: Date?, value: Int?, metaData: [String: Any]?) {
        self.type =  type
        self.target = target
        self.clientDate = clientDate
        self.value = value
        self.metaData = metaData
    }
    
    public class EventBuilder {
        var event: DVCEvent
        
        init () {
            self.event = DVCEvent(type: nil, target: nil, clientDate: nil, value: nil, metaData: nil)
        }
        
        public func type(_ type: String) -> EventBuilder {
            self.event.type = type
            return self
        }
        
        public func target(_ target: String) -> EventBuilder {
            self.event.target = target
            return self
        }
        
        public func clientDate(_ clientDate: Date) -> EventBuilder {
            self.event.clientDate = clientDate
            return self
        }
        
        public func value(_ value: Int) -> EventBuilder {
            self.event.value = value
            return self
        }
        
        public func metaData(_ metaData: [String:Any]) -> EventBuilder {
            self.event.metaData = metaData
            return self
        }
        
        public func build() throws -> DVCEvent {
            guard let _ = self.event.type else {
                throw EventError.MissingEventType
            }
            let result = self.event
            self.event = DVCEvent(type: nil, target: nil, clientDate: nil, value: nil, metaData: nil)
            return result
        }
    }
    
    public static func builder() -> EventBuilder {
        return EventBuilder()
    }
}

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
            if let variableEvaluatedEvent = self.variableEvaluated[variableKey] {
                variableEvaluatedEvent.value = variableEvaluatedEvent.value! + 1
            } else {
                self.variableEvaluated[variableKey] = DVCEvent(type: "variableEvaluated", target: variableKey, clientDate: nil, value: 1, metaData: nil)
            }
        } else {
            if let variableDefaultedEvent = self.variableDefaulted[variableKey] {
                variableDefaultedEvent.value = variableDefaultedEvent.value! + 1
            } else {
                self.variableDefaulted[variableKey] = DVCEvent(type: "variableDefaulted", target: variableKey, clientDate: nil, value: 1, metaData: nil)
            }
        }
    }
    
    func getAllAggregateEvents() -> [DVCEvent] {
        var allAggregateEvents: [DVCEvent] = []
        allAggregateEvents.append(contentsOf: self.variableDefaulted.map { (_: String, defaultedEvent: DVCEvent) -> DVCEvent in
            defaultedEvent
        })
        allAggregateEvents.append(contentsOf: self.variableEvaluated.map { (_: String, evaluatedEvent: DVCEvent) -> DVCEvent in
            evaluatedEvent
        })
        return allAggregateEvents
    }
}
