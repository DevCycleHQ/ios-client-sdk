//
//  ObjCDevCycleEvent.swift
//  DevCycle
//
//

import Foundation

@objc(DevCycleEvent)
public class ObjCDevCycleEvent: NSObject {
    @objc var type: String?
    @objc var target: String?
    @objc var clientDate: NSDate?
    @objc var value: NSNumber?
    @objc var metaData: NSDictionary?

    @objc(initializeWithType:)
    public static func initialize(type: String) -> ObjCDevCycleEvent {
        return self.initialize(type: type, target: nil, value: nil)
    }
    
    @objc(initializeWithType:target:)
    public static func initialize(type: String, target: String?) -> ObjCDevCycleEvent {
        return self.initialize(type: type, target: target, value: nil)
    }
    
    @objc(initializeWithType:target:value:)
    public static func initialize(type: String, target: String?, value: NSNumber?) -> ObjCDevCycleEvent {
        let builder = ObjCDevCycleEvent()
        builder.type = type
        builder.target = target
        builder.value = value
        return builder
    }
    
    func buildDevCycleEvent() throws -> DevCycleEvent {
        if self.type == nil {
            throw ObjCEventErrors.MissingEventType
        }
        
        var eventBuilder = DevCycleEvent.builder()
        if let eventType = self.type {
            eventBuilder = eventBuilder.type(eventType)
        }
        if let eventTarget = self.target {
            eventBuilder = eventBuilder.target(eventTarget)
        }
        if let eventDate = self.clientDate {
            eventBuilder = eventBuilder.clientDate(eventDate as Date)
        }
        if let eventValue = self.value {
            eventBuilder = eventBuilder.value(eventValue as? Double)
        }
        if let eventMetaData = self.metaData {
            eventBuilder = eventBuilder.metaData(eventMetaData as? [String : Any])
        }
        
        do {
            return try eventBuilder.build()
        } catch {
            Log.error("Error building DevCycleEvent: \(error)", tags: ["event", "build"])
            throw error
        }
    }
}

@available(*, deprecated, message: "Use DevCycleEvent")
@objc(DVCEvent)
public class ObjCDVCEvent: ObjCDevCycleEvent {}
