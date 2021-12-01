//
//  DevCycleService.swift
//  DevCycle
//
//  Created by Jason Salaber on 2021-11-30.
//

import Foundation

typealias DataResponse = (data: Data?, urlResponse: URLResponse?, error: Error?)
typealias CompletionHandler = (DataResponse) -> Void

typealias Config = (config: Any, error: Error?)
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
    
    init(config: DVCConfig) {
        let sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig)
        self.config = config
    }
    
    func getConfig(completion: @escaping ConfigCompletionHandler) {
        let configRequest = createConfigRequest(user: config.user)
        self.makeRequest(request: configRequest) { response in
            guard let config = self.processConfig(response.data) else {
                return
            }
            completion((config, response.error))
        }
    }
    
    func makeRequest(request: URLRequest, completion: CompletionHandler?) {
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
        configUrl.append("?envKey=\(config.environmentKey)")
        configUrl.append("&\(user.toString())")
        let url = URL(string: configUrl)
        return URLRequest(url: url!)
    }
}

extension DevCycleService {
    func processConfig(_ responseData: Data?) -> Any? {
        guard let data = responseData,
              let config = try? JSONSerialization.jsonObject(with: data, options: [])
        else {
            return nil
        }
        return config
    }
}
