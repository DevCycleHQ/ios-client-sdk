//
//  DevCycleUser.swift
//  DevCycle-iOS-SDK
//

import Foundation

#if canImport(UIKit)
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
    private let cacheService: CacheServiceProtocol = CacheService()

    var userId: String?
    var isAnonymous: Bool?
    var email: String?
    var name: String?
    var language: String?
    var country: String?
    var customData: [String: Any]?
    var privateCustomData: [String: Any]?

    init() {
    }

    public func userId(_ userId: String) -> UserBuilder {
        self.userId = userId
        return self
    }

    public func isAnonymous(_ isAnonymous: Bool) -> UserBuilder {
        self.isAnonymous = isAnonymous
        return self
    }

    public func email(_ email: String?) -> UserBuilder {
        self.email = email
        return self
    }

    public func name(_ name: String?) -> UserBuilder {
        self.name = name
        return self
    }

    public func language(_ language: String?) -> UserBuilder {
        self.language = language
        return self
    }

    public func country(_ country: String?) -> UserBuilder {
        self.country = country
        return self
    }

    public func customData(_ customData: [String: Any]?) -> UserBuilder {
        self.customData = customData
        return self
    }

    public func privateCustomData(_ privateCustomData: [String: Any]?) -> UserBuilder {
        self.privateCustomData = privateCustomData
        return self
    }

    private func cleanup() {
        self.userId = nil
        self.isAnonymous = nil
        self.email = nil
        self.name = nil
        self.language = nil
        self.country = nil
        self.customData = nil
        self.privateCustomData = nil
    }

    public func build() throws -> DevCycleUser {
        let hasValidUserId = self.userId != nil && !self.userId!.isEmpty

        if self.isAnonymous == false && !hasValidUserId {
            throw UserError.MissingUserIdAndIsAnonymousFalse
        }

        let finalUserId: String
        let finalIsAnonymous: Bool

        if !hasValidUserId {
            // Default case: no userId provided, make anonymous
            finalUserId = self.cacheService.getOrCreateAnonUserId()
            finalIsAnonymous = true
        } else if let userId = self.userId {
            // Valid userId provided, use it
            finalUserId = userId
            finalIsAnonymous = self.isAnonymous ?? false
        } else {
            throw UserError.InvalidUser
        }

        let customDataConverted = try self.customData.map { try CustomData.customDataFromDic($0) }
        let privateCustomDataConverted = try self.privateCustomData.map {
            try CustomData.customDataFromDic($0)
        }

        let user = DevCycleUser(
            userId: finalUserId,
            isAnonymous: finalIsAnonymous,
            email: self.email,
            name: self.name,
            language: self.language,
            country: self.country,
            customData: customDataConverted,
            privateCustomData: privateCustomDataConverted
        )

        self.cleanup()
        return user
    }
}

public class DevCycleUser: Codable {
    public var userId: String
    public var isAnonymous: Bool
    public var email: String?
    public var name: String?
    public var language: String?
    public var country: String?
    public var customData: CustomData?
    public var privateCustomData: CustomData?

    internal var lastSeenDate: Date
    internal let createdDate: Date
    internal let platform: String
    internal let platformVersion: String
    internal let deviceModel: String
    internal let sdkType: String
    internal let sdkVersion: String
    internal var appVersion: String?
    internal var appBuild: Int?

    init(
        userId: String, isAnonymous: Bool, email: String? = nil, name: String? = nil,
        language: String? = nil, country: String? = nil, customData: CustomData? = nil,
        privateCustomData: CustomData? = nil
    ) {
        self.userId = userId
        self.isAnonymous = isAnonymous
        self.email = email
        self.name = name
        self.language = language
        self.country = country
        self.customData = customData
        self.privateCustomData = privateCustomData

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
        case isAnonymous, email, name, language, country, appVersion, appBuild, customData,
            privateCustomData, lastSeenDate, createdDate, platform, platformVersion, deviceModel,
            sdkType, sdkVersion
    }

    public func update(with user: DevCycleUser) {
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
            let customDataJSON = try? JSONEncoder().encode(customData)
        {
            _ = builder.formatToQueryItem(name: "customData", value: customDataJSON)
        }
        if let privateCustomData = self.privateCustomData,
            let privateCustomDataJSON = try? JSONEncoder().encode(privateCustomData)
        {
            _ = builder.formatToQueryItem(name: "privateCustomData", value: privateCustomDataJSON)
        }

        return builder.build()
    }
}

@available(*, deprecated, message: "Use DevCycleUser")
public typealias DVCUser = DevCycleUser

class QueryItemBuilder {
    var items: [URLQueryItem]
    let user: DevCycleUser

    init(user: DevCycleUser) {
        self.items = []
        self.user = user
    }

    func formatToQueryItem<T>(name: String, value: T?) -> QueryItemBuilder {
        guard let property = value else { return self }
        if let map = property as? Data {
            items.append(
                URLQueryItem(name: name, value: String(data: map, encoding: String.Encoding.utf8)))
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
