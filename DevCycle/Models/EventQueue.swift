//
//  EventQueue.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

class EventQueue {
    var queue = DispatchQueue(label: "com.devcycle.EventQueue")
    var events: [DVCEvent] = []
    var aggregateEventQueue: DVCAggregateEvents = DVCAggregateEvents()
    
    func add(_ event: DVCEvent) {
        queue.sync {
            events.append(event)
        }
    }
    
    func add(_ events: [DVCEvent]) {
        queue.sync {
            self.events.append(contentsOf: events)
        }
    }
    
    func flush() -> [DVCEvent] {
        var eventsToFlush: [DVCEvent] = []
        queue.sync {
            eventsToFlush = self.events
            eventsToFlush.append(contentsOf: self.aggregateEventQueue.variableDefaulted.map { (_: String, defaultedEvent: DVCEvent) -> DVCEvent in
                defaultedEvent
            })
            eventsToFlush.append(contentsOf: self.aggregateEventQueue.variableEvaluated.map { (_: String, evaluatedEvent: DVCEvent) -> DVCEvent in
                evaluatedEvent
            })
            self.clear()
        }
        return eventsToFlush
    }
    
    func updateAggregateEvents(variableKey: String, variableIsDefaulted: Bool) {
        queue.sync {
            self.aggregateEventQueue.track(
                variableKey: variableKey,
                eventType: variableIsDefaulted ? DVCEventTypes.VariableDefaulted : DVCEventTypes.VariableEvaluated
            )
        }
    }
    
    func clear() {
        queue.sync {
            self.events = []
            self.aggregateEventQueue = DVCAggregateEvents()
        }
    }
}
