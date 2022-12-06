//
//  Cache.swift
//  DevCycle
//
//

import Foundation

protocol CacheServiceProtocol {
    func load() -> Cache
    func save(user: DVCUser)
    func setAnonUserId(anonUserId: String)
    func getAnonUserId() -> String?
    func clearAnonUserId()
    func setConfigUserId(user:DVCUser, userId: String?)
    func getConfigUserId(user: DVCUser) -> String?
    func setConfigFetchDate(user:DVCUser, fetchDate: Int)
    func getConfigFetchDate(user: DVCUser) -> Int?
    func saveConfig(user: DVCUser, configToSave: Data?)
    func getConfig(user: DVCUser) -> UserConfig?
}

struct Cache {
    var config: UserConfig?
    var user: DVCUser?
    var anonUserId: String?
}

class CacheService: CacheServiceProtocol {
    struct CacheKeys {
        static let user = "user"
        static let config = "config"
        static let anonUserId = "ANONYMOUS_USER_ID"
        static let identifiedConfigKey = "IDENTIFIED_CONFIG"
        static let anonymousConfigKey = "ANONYMOUS_CONFIG"
    }
    
    private let defaults: UserDefaults = UserDefaults.standard
    
    func load() -> Cache {
        var userConfig: UserConfig?
        var dvcUser: DVCUser?
        if let data = defaults.object(forKey: CacheKeys.config) as? Data,
           let dictionary = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String:Any],
           let config = try? UserConfig(from: dictionary)
        {
            userConfig = config
        }
        if let data = defaults.object(forKey: CacheKeys.user) as? Data {
            dvcUser = try? JSONDecoder().decode(DVCUser.self, from: data)
        }
        let anonUserId = self.getAnonUserId()

        return Cache(config: userConfig, user: dvcUser, anonUserId: anonUserId)
    }
    
    func save(user: DVCUser) {
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: CacheKeys.user)
        }
    }
    
    func setAnonUserId(anonUserId: String) {
        self.setString(key: CacheKeys.anonUserId, value: anonUserId)
    }
    
    func getAnonUserId() -> String? {
        return self.getString(key: CacheKeys.anonUserId)
    }
    
    func clearAnonUserId() {
        self.remove(key: CacheKeys.anonUserId)
    }
    
    func setConfigUserId(user:DVCUser, userId: String?) {
        let key = getKeyPrefix(user: user)
        if let data = userId {
            self.setString(key: "\(key).USER_ID", value: data)
        }
    }
    
    func getConfigUserId(user: DVCUser) -> String? {
        let key = getKeyPrefix(user: user)
        return self.getString(key: "\(key).USER_ID")
    }
    
    func setConfigFetchDate(user:DVCUser, fetchDate: Int) {
        let key = getKeyPrefix(user: user)
        self.setInt(key: "\(key).FETCH_DATE", value: fetchDate)
    }
    
    func getConfigFetchDate(user: DVCUser) -> Int? {
        let key = getKeyPrefix(user: user)
        return self.getInt(key: "\(key).FETCH_DATE")
    }
    
    func saveConfig(user: DVCUser, configToSave: Data?) {
        let key = getKeyPrefix(user: user)
        defaults.set(configToSave, forKey: key)
    }
    
    func getConfig(user: DVCUser) -> UserConfig? {
        let key = getKeyPrefix(user: user)
        var config: UserConfig?
        
        if let data = defaults.object(forKey: key) as? Data,
           let dictionary = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String:Any] {
            config = try? UserConfig(from: dictionary)
        }
        return config
    }
    
    private func setString(key: String, value: String) {
        defaults.set(value, forKey: key)
    }
    
    private func getString(key: String) -> String? {
        return defaults.string(forKey: key)
    }
    
    private func setInt(key: String, value: Int) {
        defaults.set(value, forKey: key)
    }
    
    private func getInt(key: String) -> Int? {
        return defaults.integer(forKey: key)
    }
    
    private func remove(key: String) {
        defaults.removeObject(forKey: key)
    }
    
    private func getKeyPrefix(user: DVCUser) -> String {
        return (user.isAnonymous ?? false) ? CacheKeys.anonymousConfigKey : CacheKeys.identifiedConfigKey
    }
}
