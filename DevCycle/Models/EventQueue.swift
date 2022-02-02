//
//  EventQueue.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

enum EventQueueErrors: Error {
    case FlushingInProgress
}

class EventQueue {
    var eventDispatchQueue = DispatchQueue(label: "com.devcycle.EventQueue")
    var events: [DVCEvent] = []
    var aggregateEventQueue: DVCAggregateEvents = DVCAggregateEvents()
    var flushing: Bool = false
    
    func queue(_ event: DVCEvent) {
        eventDispatchQueue.async {
            self.events.append(event)
        }
    }
    
    func queue(_ events: [DVCEvent]) {
        eventDispatchQueue.async {
            self.events.append(contentsOf: events)
        }
    }
    
    func flush(service: DevCycleServiceProtocol, user: DVCUser, callback: FlushCompletedHandler? = nil) {
        if (self.flushing) {
            Log.warn("Flushing already in progress, cancelling flush")
            callback?(EventQueueErrors.FlushingInProgress)
            return
        }
        
        var eventsToFlush: [DVCEvent] = []
        eventDispatchQueue.sync {
            self.flushing = true
            eventsToFlush = self.events
            eventsToFlush.append(contentsOf: self.aggregateEventQueue.variableDefaulted.map { (_: String, defaultedEvent: DVCEvent) -> DVCEvent in
                defaultedEvent
            })
            eventsToFlush.append(contentsOf: self.aggregateEventQueue.variableEvaluated.map { (_: String, evaluatedEvent: DVCEvent) -> DVCEvent in
                evaluatedEvent
            })
            self.clear()
        }
        Log.debug("Flushing events: \(eventsToFlush.count)")
        service.publishEvents(events: eventsToFlush, user: user, completion: { data, response, error in
            
            self.eventDispatchQueue.async {
                self.flushing = false
            }
            
            if let error = error {
                Log.error("Error: \(error)", tags: ["events", "flush"])
                self.queue(eventsToFlush)
            } else {
                Log.info("Submitted: \(String(describing: eventsToFlush.count)) events", tags: ["events", "flush"])
            }
            
            callback?(error)
        })
    }
    
    func updateAggregateEvents(variableKey: String, variableIsDefaulted: Bool) {
        eventDispatchQueue.async {
            self.aggregateEventQueue.track(
                variableKey: variableKey,
                eventType: variableIsDefaulted ? DVCEventTypes.VariableDefaulted : DVCEventTypes.VariableEvaluated
            )
        }
    }
    
    func clear() {
        self.events = []
        self.aggregateEventQueue = DVCAggregateEvents()
    }
}
