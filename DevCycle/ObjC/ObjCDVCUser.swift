//
//  ObjCDVCUser.swift
//  DevCycle
//
//

import Foundation

@objc(DVCUser)
public class ObjCDVCUser: NSObject {
    var user: DVCUser?
    @objc public var userId: String? {
        get { user?.userId }
    }
    @objc public var isAnonymous: NSNumber? {
        get {
            if let isAnonymous = user?.isAnonymous {
                return NSNumber(value: isAnonymous)
            }
            return nil
        }
    }
    @objc public var email: String? {
        get { user?.email }
    }
    @objc public var name: String? {
        get { user?.name }
    }
    @objc public var language: String? {
        get { user?.language }
    }
    @objc public var country: String? {
        get { user?.country }
    }
    @objc public var appVersion: String? {
        get { user?.appVersion }
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
    @objc public var publicCustomData: [String:Any]? {
        get {
            guard let publicCustomData = user?.publicCustomData,
                  let data = try? JSONSerialization.jsonObject(with: publicCustomData, options: []) as? [String: Any]
            else {
                return nil
            }
            return data
        }
    }
    
    init(builder: ObjCUserBuilder) throws {
        if builder.userId == nil && builder.isAnonymous == false {
            throw ObjCUserErrors.MissingUserId
        } else if builder.userId == nil && builder.isAnonymous == nil {
            throw ObjCUserErrors.MissingIsAnonymous
        }
        
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
            throw ObjCUserErrors.InvalidUser
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
    
    @objc(build:block:) public static func build(_ block: ((ObjCUserBuilder) -> Void)) throws -> ObjCDVCUser {
        let builder = ObjCUserBuilder()
        block(builder)
        let client = try ObjCDVCUser(builder: builder)
        return client
    }
}
