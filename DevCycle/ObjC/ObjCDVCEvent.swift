//
//  ObjCDVCEvent.swift
//  DevCycle
//
//

import Foundation

@objc(DVCEvent)
public class ObjCDVCEvent: NSObject {
    @objc var type: String
    @objc var target: String?
    @objc var date: NSDate?
    @objc var value: NSNumber?
    @objc var metaData: NSDictionary?
    
    @objc public init(type: String, target: String?, date: NSDate?, value: NSNumber?, metaData: NSDictionary?) {
        self.type = type
        if target != nil { self.target = target }
        if date != nil { self.date = date }
        if value != nil { self.value = value }
        if metaData != nil { self.metaData = metaData }
    }
}
