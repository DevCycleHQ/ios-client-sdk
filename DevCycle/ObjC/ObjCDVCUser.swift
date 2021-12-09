//
//  ObjCDVCUser.swift
//  DevCycle
//
//

import Foundation

@objc(DVCUser)
public class ObjCDVCUser: NSObject {
    var user: DVCUser?
    @objc public var properties: [String: Any] {
        guard let user = self.user else { return [:] }
        guard let userId = user.userId, let isAnonymous = user.isAnonymous else { return [:] }
        var props: [String:Any] = [
            "user_id": userId,
            "isAnonymous": NSNumber(value: isAnonymous),
        ]
        if let email = user.email {
            props["email"] = email
        }
        if let name = user.name {
            props["name"] = name
        }
        if let language = user.language {
            props["language"] = language
        }
        if let country = user.country {
            props["country"] = country
        }
        if let appVersion = user.appVersion {
            props["appVersion"] = appVersion
        }
        if let customData = user.customData {
            props["customData"] = customData
        }
        if let publicCustomData = user.publicCustomData {
            props["publicCustomData"] = publicCustomData
        }
        return props
    }
    
    init(builder: ObjCUserBuilder) {
        var userBuilder = DVCUser.builder()
        if let userId = builder.userId {
            userBuilder = userBuilder.userId(userId)
        }
        if let isAnonymous = builder.isAnonymous {
            userBuilder = userBuilder.isAnonymous(isAnonymous.boolValue)
        }
        if let email = builder.email {
            userBuilder = userBuilder.email(email)
        }
        if let name = builder.name {
            userBuilder = userBuilder.name(name)
        }
        if let language = builder.language {
            userBuilder = userBuilder.language(language)
        }
        if let country = builder.country {
            userBuilder = userBuilder.country(country)
        }
        if let appVersion = builder.appVersion {
            userBuilder = userBuilder.appVersion(appVersion)
        }
        if let customData = builder.customData {
            userBuilder = userBuilder.customData(customData)
        }
        if let publicCustomData = builder.publicCustomData {
            userBuilder = userBuilder.publicCustomData(publicCustomData)
        }
        guard let user = userBuilder.build() else {
            print("Error making user")
            return
        }
        self.user = user
    }
    
    @objc(DVCUserBuilder)
    public class ObjCUserBuilder: NSObject {
        @objc public var userId: String?
        @objc public var isAnonymous: NSNumber?
        @objc public var email: String?
        @objc public var name: String?
        @objc public var language: String?
        @objc public var country: String?
        @objc public var appVersion: String?
        @objc public var customData: [String: Any]?
        @objc public var publicCustomData: [String: Any]?
    }
    
    @objc public static func build(_ block: ((ObjCUserBuilder) -> Void)) -> ObjCDVCUser {
        let builder = ObjCUserBuilder()
        block(builder)
        return ObjCDVCUser(builder: builder)
    }
}
