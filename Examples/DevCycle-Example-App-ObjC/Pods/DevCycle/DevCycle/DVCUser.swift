//
//  DVCUser.swift
//  DevCycle-iOS-SDK
//
//

import Foundation

#if os(iOS)
import UIKit
#endif

enum UserError: Error {
    case MissingUserId
    case MissingUserIdAndIsAnonymousFalse
    case InvalidCustomDataJSON
    case InvalidPrivateCustomDataJSON
    case InvalidUser
}

public class UserBuilder {
    var user: DVCUser
    var customData: [String: Any]?
    var privateCustomData: [String: Any]?
    
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
    
    public func customData(_ customData: [String: Any]) -> UserBuilder {
        self.customData = customData
        return self
    }
    
    public func privateCustomData(_ privateCustomData: [String: Any]) -> UserBuilder {
        self.privateCustomData = privateCustomData
        return self
    }
    
    public func build() throws -> DVCUser {
        guard let _ = self.user.userId,
              let _ = self.user.isAnonymous
        else {
            throw UserError.MissingUserIdAndIsAnonymousFalse
        }
        
        if let customData = self.customData {
            self.user.customData = try CustomData.customDataFromDic(customData)
        }
        
        if let privateCustomData = self.privateCustomData {
            self.user.privateCustomData = try CustomData.customDataFromDic(privateCustomData)
        }
        
        let result = self.user
        self.user = DVCUser()
        self.customData = nil
        self.privateCustomData = nil
        return result
    }
}


public class DVCUser: Codable {
    public var userId: String?
    public var isAnonymous: Bool?
    public var email: String?
    public var name: String?
    public var language: String?
    public var country: String?
    public var appVersion: String?
    public var appBuild: Int?
    public var customData: CustomData?
    public var privateCustomData: CustomData?
    public var lastSeenDate: Date
    public let createdDate: Date
    public let platform: String
    public let platformVersion: String
    public let deviceModel: String
    public let sdkType: String
    public let sdkVersion: String
    
    init() {
        let platform = PlatformDetails()
        self.lastSeenDate = Date()
        self.createdDate = Date()
        self.platform = platform.systemName
        self.platformVersion = platform.systemVersion
        self.deviceModel = platform.deviceModel
        self.sdkType = platform.sdkType
        self.sdkVersion = platform.sdkVersion
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let appBuildStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.appBuild = Int(appBuildStr)
        }
    }
    
    enum CodingKeys: String, CodingKey {
           case userId = "user_id"
           case isAnonymous, email, name, language, country, appVersion, appBuild, customData, privateCustomData, lastSeenDate, createdDate, platform, platformVersion, deviceModel, sdkType, sdkVersion
    }
    
    public func update(with user: DVCUser) {
        self.lastSeenDate = Date()
        self.email = user.email
        self.name = user.name
        self.language = user.language
        self.country = user.country
        self.appVersion = user.appVersion
        self.appBuild = user.appBuild
        self.customData = user.customData
        self.privateCustomData = user.privateCustomData
    }
    
    public static func builder() -> UserBuilder {
        return UserBuilder()
    }
    
    func toQueryItems() -> [URLQueryItem] {
        let builder = QueryItemBuilder(user: self)
            .formatToQueryItem(name: "user_id", value: self.userId)
            .formatToQueryItem(name: "isAnonymous", value: self.isAnonymous)
            .formatToQueryItem(name: "email", value: self.email)
            .formatToQueryItem(name: "name", value: self.name)
            .formatToQueryItem(name: "language", value: self.language)
            .formatToQueryItem(name: "country", value: self.country)
            .formatToQueryItem(name: "appVersion", value: self.appVersion)
            .formatToQueryItem(name: "appBuild", value: self.appBuild)
            .formatToQueryItem(name: "lastSeenDate", value: self.lastSeenDate)
            .formatToQueryItem(name: "createdDate", value: self.createdDate)
            .formatToQueryItem(name: "platform", value: self.platform)
            .formatToQueryItem(name: "platformVersion", value: self.platformVersion)
            .formatToQueryItem(name: "deviceModel", value: self.deviceModel)
            .formatToQueryItem(name: "sdkType", value: self.sdkType)
            .formatToQueryItem(name: "sdkVersion", value: self.sdkVersion)
        
        if let customData = self.customData,
           let customDataJSON = try? JSONEncoder().encode(customData) {
            _ = builder.formatToQueryItem(name: "customData", value: customDataJSON)
        }
        if let privateCustomData = self.privateCustomData,
           let privateCustomDataJSON = try? JSONEncoder().encode(privateCustomData) {
            _ = builder.formatToQueryItem(name: "customData", value: privateCustomDataJSON)
        }
        
        return builder.build()
    }
}

class QueryItemBuilder {
    var items: [URLQueryItem]
    let user: DVCUser
    
    init(user: DVCUser) {
        self.items = []
        self.user = user
    }
    
    func formatToQueryItem<T>(name: String, value: T?) -> QueryItemBuilder {
        guard let property = value else { return self }
        if let map = property as? Data {
            items.append(URLQueryItem(name: name, value: String(data: map, encoding: String.Encoding.utf8)))
        } else if let date = property as? Date {
            items.append(URLQueryItem(name: name, value: "\(Int(date.timeIntervalSince1970))"))
        } else {
            items.append(URLQueryItem(name: name, value: "\(property)"))
        }
        
        return self
    }
    
    func build() -> [URLQueryItem] {
        let result = self.items
        self.items = []
        return result
    }
}
