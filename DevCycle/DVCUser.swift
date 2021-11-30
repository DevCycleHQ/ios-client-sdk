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
    public var lastSeenDate: Date
    public let createdDate: Date
    public let platform: String
    public let platformVersion: String
    public let deviceModel: String
    public let sdkType: String
    public let sdkVersion: String
    
    init() {
        self.lastSeenDate = Date()
        self.createdDate = Date()
        self.platform = "iOS"
        self.platformVersion = "0.0.1"
        self.deviceModel = "iPhone"
        self.sdkType = "client"
        self.sdkVersion = "0.0.1"
    }
    
    public class UserBuilder {
        var user: DVCUser
        
        init() {
            self.user = DVCUser()
        }
        
        public func userId(_ userId: String) -> UserBuilder {
            self.user.userId = userId
            self.user.isAnonymous = false
            return self
        }
        
        public func isAnonymous(_ isAnonymous: Bool) -> UserBuilder {
            if (self.user.isAnonymous != nil) { return self }
            self.user.isAnonymous = isAnonymous
            self.user.userId = UUID().uuidString
            return self
        }
        
        public func email(_ email: String) -> UserBuilder {
            self.user.email = email
            return self
        }
        
        public func name(_ name: String) -> UserBuilder {
            self.user.name = name
            return self
        }
        
        public func language(_ language: String) -> UserBuilder {
            self.user.language = language
            return self
        }
        
        public func country(_ country: String) -> UserBuilder {
            self.user.country = country
            return self
        }
        
        public func appVersion(_ appVersion: String) -> UserBuilder {
            self.user.appVersion = appVersion
            return self
        }
        
        public func appBuild(_ appBuild: Int) -> UserBuilder {
            self.user.appBuild = appBuild
            return self
        }
        
        public func customData(_ customData: [String:Any]) -> UserBuilder {
            self.user.customData = customData
            return self
        }
        
        public func publicCustomData(_ publicCustomData: [String:Any]) -> UserBuilder {
            self.user.publicCustomData = publicCustomData
            return self
        }
        
        public func build() -> DVCUser? {
            guard let _ = self.user.userId, let _ = self.user.isAnonymous else {
                return nil
            }
            
            let result = self.user
            self.user = DVCUser()
            return result
        }
    }
    
    public static func builder() -> UserBuilder {
        return UserBuilder()
    }
}

extension DVCUser {
    class StringBuilder {
        var description: String
        let user: DVCUser
        
        init(user: DVCUser) {
            self.description = ""
            self.user = user
        }
        
        func formatToQueryParam<T>(name: String, value: T?) -> StringBuilder {
            guard let property = value else { return self }
            var userParam = ""
            if let map = property as? [String: Any] {
                guard let data = try? JSONSerialization.data(withJSONObject: map, options: []) else {
                    return self
                }
                userParam = "\(name)=\(String(data: data, encoding: String.Encoding.utf8) ?? "{}")"
            } else if let date = property as? Date {
                userParam = "\(name)=\(Int(date.timeIntervalSince1970))"
            } else {
                userParam = "\(name)=\(property)"
            }
            
            if (self.description.isEmpty) {
                self.description = userParam
            } else {
                self.description.append("&\(userParam)")
            }
            return self
        }
        
        func build() -> String {
            let result = self.description
            self.description = ""
            return result
        }
    }
    
    func toString() -> String {
        let builder = StringBuilder(user: self)
            .formatToQueryParam(name: "user_id", value: self.userId)
            .formatToQueryParam(name: "isAnonymous", value: self.isAnonymous)
            .formatToQueryParam(name: "email", value: self.email)
            .formatToQueryParam(name: "name", value: self.name)
            .formatToQueryParam(name: "language", value: self.language)
            .formatToQueryParam(name: "country", value: self.country)
            .formatToQueryParam(name: "appVersion", value: self.appVersion)
            .formatToQueryParam(name: "appBuild", value: self.appBuild)
            .formatToQueryParam(name: "customData", value: self.customData)
            .formatToQueryParam(name: "publicCustomData", value: self.publicCustomData)
            .formatToQueryParam(name: "lastSeenDate", value: self.lastSeenDate)
            .formatToQueryParam(name: "createdDate", value: self.createdDate)
            .formatToQueryParam(name: "platform", value: self.platform)
            .formatToQueryParam(name: "platformVersion", value: self.platformVersion)
            .formatToQueryParam(name: "deviceModel", value: self.deviceModel)
            .formatToQueryParam(name: "sdkType", value: self.sdkType)
            .formatToQueryParam(name: "sdkVersion", value: self.sdkVersion)
        return builder.build()
    }
    

}
