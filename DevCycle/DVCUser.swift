//
//  DVCUser.swift
//  DevCycle-iOS-SDK
//
//

import Foundation

public class DVCUser {
    public var userId: String?
    public var isAnonymous: Bool
    public var email: String?
    public var name: String?
    public var language: String?
    public var country: String?
    public var appVersion: String?
    public var appBuild: Int?
    public var customData: [String:Any]?
    public var publicCustomData: [String:Any]?
    public var lastSeenDate: Date?
    public let createdDate: Date
    public let platform: String
    public let platformVersion: String
    public let deviceModel: String
    public let sdkType: String
    public let sdkVersion: String
    
    init() {
        self.isAnonymous = true
        self.createdDate = Date()
        self.platform = "iOS"
        self.platformVersion = "0.0.1"
        self.deviceModel = "iPhone"
        self.sdkType = "client"
        self.sdkVersion = "0.0.1"
    }
}
