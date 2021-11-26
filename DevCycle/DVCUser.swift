//
//  DVCUser.swift
//  DevCycle-iOS-SDK
//
//

import Foundation

public class DVCUser {
    public var userId: String?
    public var isAnonymous: Bool?
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
        self.createdDate = Date()
        self.platform = "iOS"
        self.platformVersion = "0.0.1"
        self.deviceModel = "iPhone"
        self.sdkType = "client"
        self.sdkVersion = "0.0.1"
    }
    
    class UserBuilder {
        var user: DVCUser
        
        init() {
            self.user = DVCUser()
        }
        
        func userId(userId: String) -> UserBuilder {
            self.user.userId = userId
            self.user.isAnonymous = false
            return self
        }
        
        func isAnonymous(isAnonymous: Bool) -> UserBuilder {
            self.user.isAnonymous = isAnonymous
            self.user.userId = "random_id" // TODO: Create random user id
            return self
        }
        
        func email(email: String) -> UserBuilder {
            self.user.email = email
            return self
        }
        
        func name(name: String) -> UserBuilder {
            self.user.name = name
            return self
        }
        
        func language(language: String) -> UserBuilder {
            self.user.language = language
            return self
        }
        
        func country(country: String) -> UserBuilder {
            self.user.country = country
            return self
        }
        
        func appVersion(appVersion: String) -> UserBuilder {
            self.user.appVersion = appVersion
            return self
        }
        
        func appBuild(appBuild: Int) -> UserBuilder {
            self.user.appBuild = appBuild
            return self
        }
        
        func customData(customData: [String:Any]) -> UserBuilder {
            self.user.customData = customData
            return self
        }
        
        func publicCustomData(publicCustomData: [String:Any]) -> UserBuilder {
            self.user.publicCustomData = publicCustomData
            return self
        }
        
        func build() -> DVCUser? {
            guard let _ = self.user.userId, let _ = self.user.isAnonymous else {
                return nil
            }
            
            let result = self.user
            self.user = DVCUser()
            return result
        }
    }
    
    static func builder() -> UserBuilder {
        return UserBuilder()
    }
}
