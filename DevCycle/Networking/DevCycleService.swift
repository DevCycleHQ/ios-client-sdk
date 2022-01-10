//
//  DevCycleService.swift
//  DevCycle
//
//

import Foundation

typealias DataResponse = (data: Data?, urlResponse: URLResponse?, error: Error?)
typealias CompletionHandler = (DataResponse) -> Void

typealias Config = (config: UserConfig?, error: Error?)
typealias ConfigCompletionHandler = (Config) -> Void

typealias PublishEventsCompletionHandler = (DataResponse) -> Void

struct NetworkingConstants {
    static let hostUrl = ".devcycle.com"
    static let sdkUrl = "https://sdk-api"
    static let eventsUrl = "https://events"
    
    struct Version {
        static let v1 = "/v1"
    }
    
    struct UrlPaths {
        static let config = "/mobileSDKConfig"
        static let events = "/events"
    }
}

protocol DevCycleServiceProtocol {
    func getConfig(user:DVCUser, completion: @escaping ConfigCompletionHandler)
    func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler)
}

class DevCycleService: DevCycleServiceProtocol {
    var session: URLSession
    var config: DVCConfig
    
    var cacheService: CacheServiceProtocol

    private var newUser: DVCUser?
    private var currentUser: DVCUser?
    private var configRequestInFlight: Bool = false
    private var pendingNewUserCallbacks: [ConfigCompletionHandler] = []
    private var pendingCurrentUserCallbacks: [ConfigCompletionHandler] = []
    
    init(config: DVCConfig, cacheService: CacheServiceProtocol) {
        let sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig)
        self.config = config
        self.cacheService = cacheService
    }
    
    func getConfig(user: DVCUser, completion: @escaping ConfigCompletionHandler) {
        if (configRequestInFlight) {
            if (user.userId == self.currentUser?.userId) {
                self.pendingCurrentUserCallbacks.append(completion)
            } else {
                self.newUser = user
                self.pendingNewUserCallbacks.append(completion)
            }
        } else {
            self.configRequestInFlight = true
            self.currentUser = user
            let configRequest = createConfigRequest(user: user)
            self.makeRequest(request: configRequest) { [weak self] response in
                guard let self = self else { return }

                guard let config = self.processConfig(response.data) else {
                    completion((nil, response.error))
                    for currentUserCallback in self.pendingCurrentUserCallbacks {
                        currentUserCallback((nil, response.error))
                    }
                    self.pendingCurrentUserCallbacks = []
                    self.configRequestInFlight = false
                    self.checkNewUserConfigs()
                    return
                }
                self.cacheService.save(user: user, anonymous: user.isAnonymous ?? false)
                completion((config, response.error))
                for currentUserCallback in self.pendingCurrentUserCallbacks {
                    currentUserCallback((config, response.error))
                }
                self.pendingCurrentUserCallbacks = []
                self.configRequestInFlight = false
                self.checkNewUserConfigs()
            }
        }
    }
    
    func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
        var eventsRequest = createEventsRequest()
        let userEncoder = JSONEncoder()
        userEncoder.dateEncodingStrategy = .iso8601
        guard let userId = user.userId, let userData = try? userEncoder.encode(user), let featureVariationMap = self.config.userConfig?.featureVariationMap else {
            return completion((nil, nil, ClientError.MissingUserOrFeatureVariationsMap))
        }

        let eventPayload = self.generateEventPayload(events, userId, featureVariationMap)
        guard let userBody = try? JSONSerialization.jsonObject(with: userData, options: .fragmentsAllowed) else {
            return completion((nil, nil, ClientError.MissingUserOrFeatureVariationsMap))
        }
        
        let requestBody: [String: Any] = [
            "events": eventPayload,
            "user": userBody
        ]
        
        eventsRequest.httpMethod = "POST"
        eventsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        eventsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        eventsRequest.addValue(config.environmentKey, forHTTPHeaderField: "Authorization")
        eventsRequest.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
        
        self.makeRequest(request: eventsRequest) { data, response, error in
            if error != nil || data == nil {
                return completion((data, response, error))
            }
            return completion((data, response, nil))
        }
    }
    
    func makeRequest(request: URLRequest, completion: CompletionHandler?) {
        if let urlString = request.url?.absoluteString {
            Log.debug("Making request: " + urlString, tags:["request"])
        }
        self.session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion?((data, response, error))
            }
        }.resume()
    }
    
    func createConfigRequest(user: DVCUser) -> URLRequest {
        let userQueryItems: [URLQueryItem] = user.toQueryItems()
        let urlComponents: URLComponents = createRequestUrl(type: "config", userQueryItems)
        let url = urlComponents.url!
        return URLRequest(url: url)
    }
    
    func createEventsRequest() -> URLRequest {
        let urlComponents: URLComponents = createRequestUrl(type: "event")
        let url = urlComponents.url!
        return URLRequest(url: url)
    }
    
    private func createRequestUrl(type: String, _ queryItems: [URLQueryItem] = []) -> URLComponents {
        var url: String
        var querySpecificItems: [URLQueryItem] = queryItems
        
        switch(type) {
        case "event":
            url = NetworkingConstants.eventsUrl + NetworkingConstants.hostUrl
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.events)")
        default:
            url = NetworkingConstants.sdkUrl + NetworkingConstants.hostUrl
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.config)")
            querySpecificItems.append(URLQueryItem(name: "envKey", value: config.environmentKey))
        }
        var urlComponents: URLComponents = URLComponents(string: url)!
        if (!querySpecificItems.isEmpty) {
            urlComponents.queryItems = querySpecificItems
        }
        return urlComponents
    }
    
    private func generateEventPayload(_ events: [DVCEvent], _ userId: String, _ featureVariables: [String:String]) -> [[String:Any]] {
        var eventsJSON: [[String:Any]] = []
        let formatter = ISO8601DateFormatter()
        
        for event in events {
            if event.type == nil {
                Log.debug("Skipping event, missing type: \(event)", tags: ["event"])
                continue
            }
            let eventDate: Date = event.clientDate ?? Date()
            var eventToPost: [String: Any] = [
                "type": event.type!,
                "clientDate": formatter.string(from: eventDate),
                "user_id": userId,
                "featureVars": featureVariables
            ]

            if (event.target != nil) { eventToPost["target"] = event.target }
            if (event.value != nil) { eventToPost["value"] = event.value }
            if (event.metaData != nil) { eventToPost["metaData"] = event.metaData }
            
            eventsJSON.append(eventToPost)
        }

        return eventsJSON
    }
    
    private func checkNewUserConfigs() {
        guard let user = self.newUser else {
            return
        }
    
        if (!self.pendingNewUserCallbacks.isEmpty) {
            self.currentUser = user
            self.newUser = nil
            self.pendingCurrentUserCallbacks = self.pendingNewUserCallbacks
            self.pendingNewUserCallbacks = []
            self.getConfig(user: user, completion: {_ in })
        }
    }
}

extension DevCycleService {
    func processConfig(_ responseData: Data?) -> UserConfig? {
        guard let data = responseData else {
            Log.error("No response data from request", tags: ["service", "request"])
            return nil
        }
        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
            let userConfig = try UserConfig(from: dictionary)
            cacheService.save(config: data)
            return userConfig
        } catch {
            Log.error("Failed to decode config: \(error)", tags: ["service", "request"])
        }
        return nil
    }
}
