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
    func saveConfig(user: DVCUser, fetchDate: Int, configToSave: Data?)
    func getConfig(user: DVCUser, ttlMs: Int) -> UserConfig?
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
    
    func saveConfig(user: DVCUser, fetchDate: Int, configToSave: Data?) {
        let key = getConfigKeyPrefix(user: user)
        defaults.set(configToSave, forKey: key)
        if let data = user.userId {
            self.setString(key: "\(key).USER_ID", value: data)
        }
        self.setInt(key: "\(key).FETCH_DATE", value: fetchDate)
    }
    
    func getConfig(user: DVCUser, ttlMs: Int) -> UserConfig? {
        let key = getConfigKeyPrefix(user: user)
        var config: UserConfig?
        
        let savedUserId = self.getString(key: "\(key).USER_ID")
        let savedFetchDate = self.getInt(key: "\(key).FETCH_DATE")
        
        if let userId = user.userId, userId != savedUserId {
            Log.debug("Skipping cached config: user ID does not match")
            return nil
        }
        
        let oldestValidDateMs = Int(Date().timeIntervalSince1970) - ttlMs
        if let savedFetchDate = savedFetchDate, savedFetchDate < oldestValidDateMs {
            Log.debug("Skipping cached config: last fetched date is too old")
            return nil
        }
                
        if let data = defaults.object(forKey: key) as? Data,
           let dictionary = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String:Any] {
            config = try? UserConfig(from: dictionary)
        } else {
            Log.debug("Skipping cached config: no config found")
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
    
    private func getConfigKeyPrefix(user: DVCUser) -> String {
        return (user.isAnonymous ?? false) ? CacheKeys.anonymousConfigKey : CacheKeys.identifiedConfigKey
    }
}
