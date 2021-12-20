//
//  DevCycleService.swift
//  DevCycle
//
//  Created by Jason Salaber on 2021-11-30.
//

import Foundation

typealias DataResponse = (data: Data?, urlResponse: URLResponse?, error: Error?)
typealias CompletionHandler = (DataResponse) -> Void

typealias Config = (config: UserConfig?, error: Error?)
typealias ConfigCompletionHandler = (Config) -> Void

struct NetworkingConstants {
    static let baseUrl = "https://sdk-api.devcycle.com"
    
    struct Version {
        static let v1 = "/v1"
    }
    
    struct UrlPaths {
        static let config = "/sdkConfig"
    }
}

protocol DevCycleServiceProtocol {
    func getConfig(completion: @escaping ConfigCompletionHandler)
}

class DevCycleService: DevCycleServiceProtocol {
    var session: URLSession
    var config: DVCConfig
    
    var cacheService: CacheServiceProtocol
    
    init(config: DVCConfig, cacheService: CacheServiceProtocol) {
        let sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig)
        self.config = config
        self.cacheService = cacheService
    }
    
    func getConfig(completion: @escaping ConfigCompletionHandler) {
        cacheService.save(user: config.user)
        let configRequest = createConfigRequest(user: config.user)
        self.makeRequest(request: configRequest) { response in
            guard let config = self.processConfig(response.data) else {
                completion((nil, response.error))
                return
            }
            completion((config, response.error))
        }
    }
    
    func makeRequest(request: URLRequest, completion: CompletionHandler?) {
        if let urlString = request.url?.absoluteString {
            print("Making request: " + urlString)
        }
        self.session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion?((data, response, error))
            }
        }.resume()
    }
    
    func createConfigRequest(user: DVCUser) -> URLRequest {
        var configUrl = NetworkingConstants.baseUrl
        configUrl.append("\(NetworkingConstants.Version.v1)")
        configUrl.append("\(NetworkingConstants.UrlPaths.config)")
        var urlComponents = URLComponents(string: configUrl)
        var queryItems = user.toQueryItems()
        queryItems.append(URLQueryItem(name: "envKey", value: config.environmentKey))
        urlComponents?.queryItems = queryItems
        let url = urlComponents!.url!
        return URLRequest(url: url)
    }
}

extension DevCycleService {
    func processConfig(_ responseData: Data?) -> UserConfig? {
        guard let data = responseData else {
            print("No config data")
            return nil
        }
        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
            let userConfig = try UserConfig(from: dictionary)
            cacheService.save(config: data)
            return userConfig
        } catch {
            print("Failed to decode config: \(error)")
        }
        return nil
    }
}
