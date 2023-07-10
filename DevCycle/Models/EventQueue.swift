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
    var events: [DevCycleEvent] = []
    var aggregateEventQueue: DVCAggregateEvents = DVCAggregateEvents()
    var flushing: Bool = false
    
    func queue(_ event: DevCycleEvent) {
        eventDispatchQueue.async {
            self.events.append(event)
        }
    }
    
    func queue(_ events: [DevCycleEvent]) {
        eventDispatchQueue.async {
            self.events.append(contentsOf: events)
        }
    }
    
    func flush(service: DevCycleServiceProtocol, user: DevCycleUser, callback: FlushCompletedHandler? = nil) {
        if (self.flushing) {
            Log.warn("Flushing already in progress, cancelling flush")
            callback?(EventQueueErrors.FlushingInProgress)
            return
        }
        
        var eventsToFlush: [DevCycleEvent] = []
        eventDispatchQueue.sync {
            self.flushing = true
            eventsToFlush = self.events
            eventsToFlush.append(contentsOf: aggregateEventQueue.getAllAggregateEvents())
            self.clear()
        }
        Log.debug("Flushing events: \(eventsToFlush.count)")
        service.publishEvents(events: eventsToFlush, user: user, completion: { data, response, error in
            if let error = error, !(400...499).contains((error as NSError).code) {
                Log.error("Retryable Error: \(error)", tags: ["events", "flush"])
                self.queue(eventsToFlush)
            } else if let response = response as? HTTPURLResponse, (200...399).contains(response.statusCode) {
                Log.info("Submitted: \(String(describing: eventsToFlush.count)) events", tags: ["events", "flush"])
            } else {
                Log.error("Something went wrong with sending events, dropping events: \(eventsToFlush)", tags: ["events", "flush"])
            }
            
            self.eventDispatchQueue.async {
                self.flushing = false
            }
            
            callback?(error)
        })
    }
    
    func isEmpty() -> Bool {
        eventDispatchQueue.sync {
            return self.events.isEmpty && self.aggregateEventQueue.variableDefaulted.isEmpty && self.aggregateEventQueue.variableEvaluated.isEmpty
        }
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
