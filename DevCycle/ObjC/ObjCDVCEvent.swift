//
//  ObjCDVCEvent.swift
//  DevCycle
//
//

import Foundation

@objc(DVCEvent)
public class ObjCDVCEvent: NSObject {
    @objc var type: String?
    @objc var target: String?
    @objc var clientDate: NSDate?
    @objc var value: NSNumber?
    @objc var metaData: NSDictionary?

    @objc(initializeWithType:)
    public static func initialize(type: String) -> ObjCDVCEvent {
        return self.initialize(type: type, target: nil, value: nil)
    }
    
    @objc(initializeWithType:target:)
    public static func initialize(type: String, target: String?) -> ObjCDVCEvent {
        return self.initialize(type: type, target: target, value: nil)
    }
    
    @objc(initializeWithType:target:value:)
    public static func initialize(type: String, target: String?, value: NSNumber?) -> ObjCDVCEvent {
        let builder = ObjCDVCEvent()
        builder.type = type
        builder.target = target
        builder.value = value
        return builder
    }
    
    func buildDVCEvent() throws -> DVCEvent {
        if self.type == nil {
            throw ObjCEventErrors.MissingEventType
        }
        
        var eventBuilder = DVCEvent.builder()
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
            eventBuilder = eventBuilder.value(eventValue as! Double)
        }
        if let eventMetaData = self.metaData {
            eventBuilder = eventBuilder.metaData(eventMetaData as! [String : Any])
        }
        
        do {
            return try eventBuilder.build()
        } catch {
            Log.error("Error building DVCEvent: \(error)", tags: ["event", "build"])
            throw error
        }
    }
}
