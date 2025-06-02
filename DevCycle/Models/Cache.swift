//
//  Cache.swift
//  DevCycle
//
//

import Foundation

protocol CacheServiceProtocol {
    func load() -> Cache
    func save(user: DevCycleUser)
    func setAnonUserId(anonUserId: String)
    func getAnonUserId() -> String?
    func clearAnonUserId()
    func saveConfig(user: DevCycleUser, fetchDate: Int, configToSave: Data?)
    func getConfig(user: DevCycleUser, ttlMs: Int) -> UserConfig?
    func getOrCreateAnonUserId() -> String
    func migrateLegacyCache()
}

struct Cache {
    var config: UserConfig?
    var user: DevCycleUser?
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
        migrateLegacyCache()

        var userConfig: UserConfig?
        var dvcUser: DevCycleUser?
        if let data = defaults.object(forKey: CacheKeys.config) as? Data,
            let dictionary = try? JSONSerialization.jsonObject(
                with: data, options: .fragmentsAllowed) as? [String: Any],
            let config = try? UserConfig(from: dictionary)
        {
            userConfig = config
        }
        if let data = defaults.object(forKey: CacheKeys.user) as? Data {
            dvcUser = try? JSONDecoder().decode(DevCycleUser.self, from: data)
        }
        let anonUserId = self.getAnonUserId()

        return Cache(config: userConfig, user: dvcUser, anonUserId: anonUserId)
    }

    func save(user: DevCycleUser) {
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

    func saveConfig(user: DevCycleUser, fetchDate: Int, configToSave: Data?) {
        let key = getConfigKeyPrefix(user: user)
        defaults.set(configToSave, forKey: key)
        if let data = user.userId {
            self.setString(key: "\(key).USER_ID", value: data)
        }
        self.setInt(key: "\(key).FETCH_DATE", value: fetchDate)
    }

    func getConfig(user: DevCycleUser, ttlMs: Int) -> UserConfig? {
        let key = getConfigKeyPrefix(user: user)
        var config: UserConfig?

        let savedUserId = self.getString(key: "\(key).USER_ID")
        let savedFetchDate = self.getInt(key: "\(key).FETCH_DATE")

        if let userId = user.userId, userId != savedUserId {
            Log.debug("Skipping cached config: user ID does not match")
            return nil
        }

        let currentTimeSec = Int(Date().timeIntervalSince1970)
        let ttlSec = ttlMs / 1000
        let oldestValidTimeSec = currentTimeSec - ttlSec
        if let savedFetchDate = savedFetchDate, savedFetchDate < oldestValidTimeSec {
            Log.debug("Skipping cached config: last fetched date is too old")
            return nil
        }

        if let data = defaults.object(forKey: key) as? Data,
            let dictionary = try? JSONSerialization.jsonObject(
                with: data, options: .fragmentsAllowed) as? [String: Any]
        {
            config = try? UserConfig(from: dictionary)
        } else {
            Log.debug("Skipping cached config: no config found")
        }

        return config
    }

    func getOrCreateAnonUserId() -> String {
        if let anonId = getAnonUserId() {
            return anonId
        }
        let newAnonId = UUID().uuidString
        setAnonUserId(anonUserId: newAnonId)
        return newAnonId
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
        let value = defaults.integer(forKey: key)
        // UserDefaults.integer returns 0 if key doesn't exist, so we need to check if key actually exists
        if defaults.object(forKey: key) == nil {
            return nil
        }
        return value
    }

    private func remove(key: String) {
        defaults.removeObject(forKey: key)
    }

    private func getConfigKeyPrefix(user: DevCycleUser) -> String {
        if user.isAnonymous ?? false {
            // For anonymous users, use the anonUserId if available, otherwise use the base key
            if let anonUserId = user.userId {
                return "\(CacheKeys.anonymousConfigKey)_\(anonUserId)"
            } else {
                return CacheKeys.anonymousConfigKey
            }
        } else {
            // For identified users, include the userId in the cache key
            if let userId = user.userId {
                return "\(CacheKeys.identifiedConfigKey)_\(userId)"
            } else {
                return CacheKeys.identifiedConfigKey
            }
        }
    }

    func migrateLegacyCache() {
        migrateConfigIfNeeded(
            oldKey: CacheKeys.identifiedConfigKey,
            userType: .identified
        )
        migrateConfigIfNeeded(
            oldKey: CacheKeys.anonymousConfigKey,
            userType: .anonymous
        )
    }

    private enum UserType {
        case identified, anonymous
    }

    private func migrateConfigIfNeeded(oldKey: String, userType: UserType) {
        guard let oldConfigData = defaults.object(forKey: oldKey) as? Data else {
            return
        }

        guard let oldUserId = getString(key: "\(oldKey).USER_ID") else {
            Log.debug("Migration skipped: No user ID found for legacy cache key \(oldKey)")
            return
        }

        guard let oldFetchDate = getInt(key: "\(oldKey).FETCH_DATE") else {
            Log.debug("Migration skipped: No fetch date found for legacy cache key \(oldKey)")
            return
        }

        let newKey =
            userType == .identified
            ? "\(CacheKeys.identifiedConfigKey)_\(oldUserId)"
            : "\(CacheKeys.anonymousConfigKey)_\(oldUserId)"

        if defaults.object(forKey: newKey) != nil {
            Log.debug("New cache key \(newKey) already exists, cleaning up legacy cache \(oldKey)")
            defaults.removeObject(forKey: oldKey)
            remove(key: "\(oldKey).USER_ID")
            remove(key: "\(oldKey).FETCH_DATE")
            return
        }

        defaults.set(oldConfigData, forKey: newKey)
        setString(key: "\(newKey).USER_ID", value: oldUserId)
        setInt(key: "\(newKey).FETCH_DATE", value: oldFetchDate)

        defaults.removeObject(forKey: oldKey)
        remove(key: "\(oldKey).USER_ID")
        remove(key: "\(oldKey).FETCH_DATE")

        Log.debug("Migrated config + user cache from \(oldKey) to \(newKey)")
    }
}
