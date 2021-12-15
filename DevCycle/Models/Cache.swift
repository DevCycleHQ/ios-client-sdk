//
//  Cache.swift
//  DevCycle
//
//

import Foundation

protocol CacheServiceProtocol {
    func load() -> Cache
    func save(user: DVCUser)
    func save(config: Data)
}

struct Cache {
    var config: UserConfig?
    var user: DVCUser?
}

class CacheService: CacheServiceProtocol {
    struct CacheKeys {
        static let user = "user"
        static let config = "config"
    }
    
    func load() -> Cache {
        let defaults = UserDefaults.standard
        var userConfig: UserConfig?
        var dvcUser: DVCUser?
        if let data = defaults.object(forKey: CacheKeys.config) as? Data {
            userConfig = try? JSONDecoder().decode(UserConfig.self, from: data)
        }
        if let data = defaults.object(forKey: CacheKeys.user) as? Data {
            dvcUser = try? JSONDecoder().decode(DVCUser.self, from: data)
        }
        
        return Cache(config: userConfig, user: dvcUser)
    }
    
    func save(config: Data) {
        let defaults = UserDefaults.standard
        defaults.set(config, forKey: CacheKeys.config)
    }
    
    func save(user: DVCUser) {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: CacheKeys.user)
        }
    }
}
