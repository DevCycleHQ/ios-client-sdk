//
//  ObjCDVCEvent.swift
//  DevCycle
//
//

import Foundation

@objc(DVCEvent)
public class ObjCDVCEvent: NSObject {
    var event: DVCEvent?
    @objc var type: String?
    @objc var target: String?
    @objc var clientDate: NSDate?
    @objc var value: NSNumber?
    @objc var metaData: NSDictionary?

    init(builder: ObjCEventBuilder) throws {
        if builder.type == nil {
            throw ObjCEventErrors.MissingEventType
        }
        
        var eventBuilder = DVCEvent.builder()
        if let eventType = builder.type {
            eventBuilder = eventBuilder.type(eventType)
        }
        if let eventTarget = builder.target {
            eventBuilder = eventBuilder.target(eventTarget)
        }
        if let eventDate = builder.clientDate {
            eventBuilder = eventBuilder.clientDate(eventDate as Date)
        }
        if let eventValue = builder.value {
            eventBuilder = eventBuilder.value(eventValue as! Int)
        }
        if let eventMetaData = builder.metaData {
            eventBuilder = eventBuilder.metaData(eventMetaData as! [String : Any])
        }
        guard let event = try? eventBuilder.build() else {
            print("Error making event")
            throw ObjCEventErrors.InvalidEvent
        }
        self.event = event
    }
    
    @objc(DVCEventBuilder)
    public class ObjCEventBuilder: NSObject {
        @objc public var type: String?
        @objc public var target: String?
        @objc public var clientDate: NSDate?
        @objc public var value: NSNumber?
        @objc public var metaData: NSDictionary?
    }
    
    @objc(build:block:) public static func build(_ block: ((ObjCEventBuilder) -> Void)) throws -> ObjCDVCEvent {
        let builder = ObjCEventBuilder()
        block(builder)
        let event = try ObjCDVCEvent(builder: builder)
        return event
    }
}
