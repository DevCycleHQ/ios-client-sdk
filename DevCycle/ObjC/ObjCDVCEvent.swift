//
//  ObjCDVCEvent.swift
//  DevCycle
//
//  Created by Kaushal Kapasi on 2021-12-15.
//

import Foundation

@objc(DVCEvent)
public class ObjCDVCEvent: NSObject {
    var type: String = ""
    var target: String?
    var date: NSDate?
    var value: Int?
    var metaData: [String: Any]?
}
