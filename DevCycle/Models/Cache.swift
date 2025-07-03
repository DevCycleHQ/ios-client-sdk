//
//  Cache.swift
//  DevCycle
//
//

import Foundation

protocol CacheServiceProtocol {
    func setAnonUserId(anonUserId: String)
    func getAnonUserId() -> String?
    func clearAnonUserId()
    func saveConfig(user: DevCycleUser, configToSave: Data?)
    func getConfig(user: DevCycleUser) -> UserConfig?
    func getOrCreateAnonUserId() -> String
    func migrateLegacyCache()
}

class CacheService: CacheServiceProtocol {
    struct CacheKeys {
        static let platform = PlatformDetails()
        static let versionPrefix = "VERSION_\(platform.sdkVersion)"
        
        static let anonUserId = "ANONYMOUS_USER_ID"
        static let identifiedConfigKey = "\(versionPrefix).IDENTIFIED_CONFIG"
        static let anonymousConfigKey = "\(versionPrefix).ANONYMOUS_CONFIG"
        static let userIdSuffix = ".USER_ID"
        static let expiryDateSuffix = ".EXPIRY_DATE"

        // Legacy keys for cleanup
        static let legacyUser = "user"
        static let legacyConfig = "config"
        static let legacyFetchDateSuffix = ".FETCH_DATE"
    }

    private let defaults: UserDefaults = UserDefaults.standard
    private let configCacheTTL: Int

    init(configCacheTTL: Int = DEFAULT_CONFIG_CACHE_TTL) {
        self.configCacheTTL = configCacheTTL
        migrateLegacyCache()
    }

    func setAnonUserId(anonUserId: String) {
        defaults.set(anonUserId, forKey: CacheKeys.anonUserId)
    }

    func getAnonUserId() -> String? {
        return defaults.string(forKey: CacheKeys.anonUserId)
    }

    func clearAnonUserId() {
        defaults.removeObject(forKey: CacheKeys.anonUserId)
    }

    func saveConfig(user: DevCycleUser, configToSave: Data?) {
        let key = getConfigKeyPrefix(user: user)
        defaults.set(configToSave, forKey: key)

        let expiryDate = currentTimeMs() + configCacheTTL
        defaults.set(expiryDate, forKey: "\(key)\(CacheKeys.expiryDateSuffix)")
    }

    func getConfig(user: DevCycleUser) -> UserConfig? {
        let key = getConfigKeyPrefix(user: user)

        // Check if cache has expired
        if let savedExpiryDate = getIntValue(forKey: "\(key)\(CacheKeys.expiryDateSuffix)"),
            currentTimeMs() > savedExpiryDate
        {
            Log.debug("Skipping cached config: config has expired")
            cleanupCacheEntry(key: key)
            return nil
        }

        // Try to load and parse cached config
        guard let data = defaults.object(forKey: key) as? Data,
            let dictionary = try? JSONSerialization.jsonObject(
                with: data, options: .fragmentsAllowed) as? [String: Any],
            let config = try? UserConfig(from: dictionary)
        else {
            Log.debug("Skipping cached config: no config found")
            return nil
        }

        return config
    }

    func getOrCreateAnonUserId() -> String {
        if let existingId = getAnonUserId() {
            return existingId
        }

        let newId = UUID().uuidString
        setAnonUserId(anonUserId: newId)
        return newId
    }

    // MARK: - Private Helper Methods

    private func currentTimeMs() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    private func getIntValue(forKey key: String) -> Int? {
        return defaults.object(forKey: key) != nil ? defaults.integer(forKey: key) : nil
    }

    private func cleanupCacheEntry(key: String) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: "\(key)\(CacheKeys.expiryDateSuffix)")
    }

    private func cleanupLegacyCacheEntry(key: String) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: "\(key)\(CacheKeys.userIdSuffix)")
        defaults.removeObject(forKey: "\(key)\(CacheKeys.legacyFetchDateSuffix)")
    }

    private func getConfigKeyPrefix(user: DevCycleUser) -> String {
        let baseKey =
            user.isAnonymous
            ? CacheKeys.anonymousConfigKey : CacheKeys.identifiedConfigKey

        if !user.userId.isEmpty {
            return "\(baseKey)_\(user.userId)"
        }

        return baseKey
    }

    // MARK: - Legacy Cache Migration

    func migrateLegacyCache() {
        // Migrate config cache
        migrateConfigIfNeeded(oldKey: CacheKeys.identifiedConfigKey, isIdentified: true)
        migrateConfigIfNeeded(oldKey: CacheKeys.anonymousConfigKey, isIdentified: false)

        // Clean up legacy user cache
        cleanupLegacyUserCache()

        // Clean up legacy config cache
        cleanupLegacyConfigCache()
    }

    private func cleanupLegacyUserCache() {
        if defaults.object(forKey: CacheKeys.legacyUser) != nil {
            defaults.removeObject(forKey: CacheKeys.legacyUser)
            Log.debug("Cleaned up legacy user cache")
        }
    }

    private func cleanupLegacyConfigCache() {
        if defaults.object(forKey: CacheKeys.legacyConfig) != nil {
            defaults.removeObject(forKey: CacheKeys.legacyConfig)
            Log.debug("Cleaned up legacy config cache")
        }
    }

    private func migrateConfigIfNeeded(oldKey: String, isIdentified: Bool) {
        guard let oldConfigData = defaults.object(forKey: oldKey) as? Data,
            let oldUserId = defaults.string(forKey: "\(oldKey)\(CacheKeys.userIdSuffix)")
        else {
            return
        }

        let newKey =
            isIdentified
            ? "\(CacheKeys.identifiedConfigKey)_\(oldUserId)"
            : "\(CacheKeys.anonymousConfigKey)_\(oldUserId)"

        // If new cache already exists, just cleanup legacy cache
        if defaults.object(forKey: newKey) != nil {
            Log.debug("New cache key \(newKey) already exists, cleaning up legacy cache \(oldKey)")
            cleanupLegacyCacheEntry(key: oldKey)
            return
        }

        // Migrate data to new format
        defaults.set(oldConfigData, forKey: newKey)

        let expiryDate = currentTimeMs() + configCacheTTL
        defaults.set(expiryDate, forKey: "\(newKey)\(CacheKeys.expiryDateSuffix)")

        // Cleanup old cache
        cleanupLegacyCacheEntry(key: oldKey)

        Log.debug("Migrated config + user cache from \(oldKey) to \(newKey)")
    }
}
