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
    
    @objc public class ObjCUserBuilder: NSObject {
        var objcUser: ObjCDVCUser
        var userBuilder: DVCUser.UserBuilder
        
        override init() {
            self.objcUser = ObjCDVCUser()
            self.userBuilder = DVCUser.builder()
        }
        
        @objc public func userId(_ userId: String) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.userId(userId)
            return self
        }
        
        @objc public func isAnonymous(_ isAnonymous: Bool) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.isAnonymous(isAnonymous)
            return self
        }
        
        @objc public func email(_ email: String) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.email(email)
            return self
        }
        
        @objc public func name(_ name: String) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.name(name)
            return self
        }
        
        @objc public func language(_ language: String) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.language(language)
            return self
        }
        
        @objc public func country(_ country: String) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.country(country)
            return self
        }
        
        @objc public func appVersion(_ appVersion: String) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.appVersion(appVersion)
            return self
        }
        
        @objc public func appBuild(_ appBuild: Int) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.appBuild(appBuild)
            return self
        }
        
        @objc public func customData(_ customData: [String:Any]) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.customData(customData)
            return self
        }
        
        @objc public func publicCustomData(_ publicCustomData: [String:Any]) -> ObjCUserBuilder {
            self.userBuilder = self.userBuilder.publicCustomData(publicCustomData)
            return self
        }
        
        @objc public func build() -> ObjCDVCUser? {
            guard let result = self.userBuilder.build() else {
                print("Something went wrong with building user")
                return nil
            }
            self.objcUser.user = result
            self.userBuilder = DVCUser.builder()
            return self.objcUser
        }
    }
    
    @objc public static func builder() -> ObjCUserBuilder {
        return ObjCUserBuilder()
    }
}
