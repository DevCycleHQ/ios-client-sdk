//
//  ObjCDVCUser.swift
//  DevCycle
//
//

import Foundation

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
    @objc public var privateCustomData: [String: Any]?
    
    @objc(initializeWithUserId:)
    public static func initialize(userId: String?) -> ObjCUserBuilder {
        let builder = ObjCUserBuilder()
        builder.userId = userId
        return builder
    }
}

@objc(DVCUser)
public class ObjCDVCUser: NSObject {
    var user: DVCUser?
    @objc public var userId: String? { return user?.userId }
    @objc public var isAnonymous: NSNumber? {
        get {
            if let isAnonymous = user?.isAnonymous {
                return NSNumber(value: isAnonymous)
            }
            return nil
        }
    }
    @objc public var email: String? { return user?.email }
    @objc public var name: String? { return user?.name }
    @objc public var language: String? { return user?.language }
    @objc public var country: String? { return user?.country }
    @objc public var appVersion: String? { return user?.appVersion }
    @objc public var appBuild: NSNumber? {
        guard let appBuild = user?.appBuild else { return nil }
        return NSNumber(integerLiteral: appBuild)
    }
    @objc public var customData: [String:Any]? {
        get {
            guard let customData = user?.customData,
                  let data = try? JSONSerialization.jsonObject(with: customData, options: []) as? [String: Any]
            else {
                return nil
            }
            return data
        }
    }
    @objc public var privateCustomData: [String:Any]? {
        get {
            guard let privateCustomData = user?.privateCustomData,
                  let data = try? JSONSerialization.jsonObject(with: privateCustomData, options: []) as? [String: Any]
            else {
                return nil
            }
            return data
        }
    }
    
    @objc(build:block:)
    public static func build(_ block: ((ObjCUserBuilder) -> Void)) throws -> ObjCDVCUser {
        let builder = ObjCUserBuilder()
        block(builder)
        let user = try ObjCDVCUser(builder: builder)
        return user
    }
    
    init(builder: ObjCUserBuilder) throws {
        var userBuilder = DVCUser.builder()
        if let userId = builder.userId {
            userBuilder = userBuilder.userId(userId)
        } else {
            userBuilder = userBuilder.isAnonymous(true)
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
        if let privateCustomData = builder.privateCustomData {
            userBuilder = userBuilder.privateCustomData(privateCustomData)
        }
        guard let user = try? userBuilder.build() else {
            Log.error("Error making user", tags: ["user", "build"])
            throw ObjCUserErrors.InvalidUser
        }
        self.user = user
    }
}
