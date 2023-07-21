//
//  ObjCDVCUser.swift
//  DevCycle
//
//

import Foundation

@objc(DevCycleUser)
public class ObjCDevCycleUser: NSObject {
    @objc public var userId: String?
    @objc public var isAnonymous: NSNumber?
    @objc public var email: String?
    @objc public var name: String?
    @objc public var language: String?
    @objc public var country: String?
    @objc public var customData: [String: Any]?
    @objc public var privateCustomData: [String: Any]?
    
    public override init() {
        self.isAnonymous = true
    }
    
    @objc(initializeWithUserId:)
    public static func initialize(userId: String?) -> ObjCDevCycleUser {
        let builder = ObjCDevCycleUser()
        if (userId == nil) {
            builder.isAnonymous = true
        } else {
            builder.userId = userId
            builder.isAnonymous = false
        }
        return builder
    }
    
    func buildDevCycleUser() throws -> DevCycleUser {
        var userBuilder = DevCycleUser.builder()
        if let userId = self.userId {
            userBuilder = userBuilder.userId(userId)
        } else {
            userBuilder = userBuilder.isAnonymous(true)
        }
        if let isAnonymous = self.isAnonymous {
            userBuilder = userBuilder.isAnonymous(isAnonymous.boolValue)
        }
        if let email = self.email {
            userBuilder = userBuilder.email(email)
        }
        if let name = self.name {
            userBuilder = userBuilder.name(name)
        }
        if let language = self.language {
            userBuilder = userBuilder.language(language)
        }
        if let country = self.country {
            userBuilder = userBuilder.country(country)
        }
        if let customData = self.customData {
            userBuilder = userBuilder.customData(customData)
        }
        if let privateCustomData = self.privateCustomData {
            userBuilder = userBuilder.privateCustomData(privateCustomData)
        }
        
        do {
            return try userBuilder.build()
        } catch {
            Log.error("Error building DevCycleUser: \(error)", tags: ["user", "build"])
            throw error
        }
    }
}

@available(*, deprecated, message: "Use DevCycleUser")
@objc(DVCUser)
public class ObjCDVCUser: ObjCDevCycleUser {}

