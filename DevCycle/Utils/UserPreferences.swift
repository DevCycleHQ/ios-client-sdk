struct UserPreferencesKeys {
    static let AnonUserIdKey = "ANON_USER_ID"
}

class UserPreferences {
    private var defaults: UserDefaults = UserDefaults.standard
    
    @objc func setAnonUserId(userId: String) {
        setString(key: UserPreferencesKeys.AnonUserIdKey, value: userId)
    }
    
    @objc func getAnonUserId() -> String? {
        return getString(key: UserPreferencesKeys.AnonUserIdKey)
    }
    
    @objc func removeAnonUserId() {
        remove(key: UserPreferencesKeys.AnonUserIdKey)
    }
    
    private func setString(key: String, value: String) {
        defaults.set(value, forKey: key)
    }
    
    private func getString(key: String) -> String? {
        return defaults.string(forKey: key)
    }
    
    private func remove(key: String) {
        defaults.removeObject(forKey: key)
    }
}
