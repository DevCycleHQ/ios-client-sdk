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
        self.target = target
        self.date = date
        self.value = value
        self.metaData = metaData
    }
}
