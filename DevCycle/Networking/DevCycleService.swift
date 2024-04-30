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

typealias SaveEntityCompletionHandler = (DataResponse) -> Void

enum APIError: Error {
    case NoResponse
    case StatusResponse(status: Int, message: String)
    
    public var debugDescription: String {
        switch self {
        case .StatusResponse(status: let status, message: let message):
            return "API Error Status: \(status), message: \(message)"
        case .NoResponse:
            return "No API Response"
        }
    }
    
    public var debugTags: [String] {
        switch self {
        case .StatusResponse(status: let status, message: _):
            return ["api", String(describing: status)]
        case .NoResponse:
            return ["api"]
        }
    }
}

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
        static let edgeDB = "/edgedb"
    }
}

struct RequestParams {
    var sse: Bool
    var lastModified: Int?
    var etag: String?
}

protocol DevCycleServiceProtocol {
    func getConfig(user:DevCycleUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler)
    func publishEvents(events: [DevCycleEvent], user: DevCycleUser, completion: @escaping PublishEventsCompletionHandler)
    func saveEntity(user:DevCycleUser, completion: @escaping SaveEntityCompletionHandler)
    func makeRequest(request: URLRequest, completion: @escaping CompletionHandler)
}

class DevCycleService: DevCycleServiceProtocol {
    var session: URLSession
    var config: DVCConfig
    var options: DevCycleOptions?
    
    var cacheService: CacheServiceProtocol
    var requestConsolidator: RequestConsolidator!

    private var newUser: DevCycleUser?
    private var maxBatchSize = 100
    
    init(config: DVCConfig, cacheService: CacheServiceProtocol, options: DevCycleOptions? = nil) {
        let sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig)
        self.config = config
        self.options = options
        self.cacheService = cacheService
        self.requestConsolidator = RequestConsolidator(service: self, cacheService: cacheService)
    }
    
    func getConfig(user: DevCycleUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler) {
        let configRequest = createConfigRequest(user: user, enableEdgeDB: enableEdgeDB, extraParams: extraParams)
        requestConsolidator.queue(request: configRequest, user: user, callback: completion)
    }
    
    func publishEvents(events: [DevCycleEvent], user: DevCycleUser, completion: @escaping PublishEventsCompletionHandler) {
        let userEncoder = JSONEncoder()
        userEncoder.dateEncodingStrategy = .iso8601
        guard let userId = user.userId, let userData = try? userEncoder.encode(user) else {
            return completion((nil, nil, ClientError.MissingUser))
        }
        
        let eventPayload = self.generateEventPayload(events, userId, self.config.userConfig?.featureVariationMap)
        guard let userBody = try? JSONSerialization.jsonObject(with: userData, options: .fragmentsAllowed) else {
            return completion((nil, nil, ClientError.InvalidUser))
        }

        self.sendEventsPayload(events: eventPayload, user: userBody, completion: completion)
    }
    
    func saveEntity(user: DevCycleUser, completion: @escaping SaveEntityCompletionHandler) {
        var saveEntityRequest = createSaveEntityRequest()
        
        guard let userIsAnonymous = user.isAnonymous, !userIsAnonymous else {
            Log.error("Cannot save user data for an anonymous user!")
            return
        }
        
        let userEncoder = JSONEncoder()
        userEncoder.dateEncodingStrategy = .iso8601
        
        guard let userData = try? userEncoder.encode(user) else {
            return completion((nil, nil, ClientError.MissingUserOrFeatureVariationsMap))
        }
        
        guard let userBody = try? JSONSerialization.jsonObject(with: userData, options: .fragmentsAllowed) else {
            return completion((nil, nil, ClientError.MissingUserOrFeatureVariationsMap))
        }
        
        saveEntityRequest.httpMethod = "PATCH"
        saveEntityRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        saveEntityRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        saveEntityRequest.addValue(config.sdkKey, forHTTPHeaderField: "Authorization")
        if let jsonBody = try? JSONSerialization.data(withJSONObject: userBody, options: .prettyPrinted) {
           // build the save entity request with this data object
            Log.info("Save entity payload: \(String(data: jsonBody, encoding: .utf8) ?? "")")
            saveEntityRequest.httpBody = jsonBody
        } else {
            Log.error("Invalid user data")
            return completion((nil, nil, ClientError.InvalidUser))
        }
        
        self.makeRequest(request: saveEntityRequest) { data, response, error in
            return completion((data, response, error))
        }
    }

    func makeRequest(request: URLRequest, completion: @escaping CompletionHandler) {
        let startTime = CFAbsoluteTimeGetCurrent()
        if let urlString = request.url?.absoluteString {
            Log.debug("Making request: \(urlString)", tags:["request"])
        }
        
        self.session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let responseData = data,
                      let responseDataJson = try? JSONSerialization.jsonObject(with: responseData, options: .fragmentsAllowed) as? [String:Any]
                else {
                    Log.error("Unable to parse API Response", tags: ["api"])
                    completion((nil, nil, APIError.NoResponse))
                    return
                }
                
                // Guard below checks if statusCode exists or not in the response body.
                // Only API Errors (http status codes of 4xx/5xx) have the statusCode in the response body, successful API Requests (http status codes of 2xx/3xx) calls will not.
                guard responseDataJson["statusCode"] == nil else {
                    let status = responseDataJson["statusCode"] as! Int
                    var errorResponse: String
                    if (responseDataJson["message"] is [String]) {
                        errorResponse = (responseDataJson["message"] as! [String]).joined(separator: ", ")
                    } else {
                        errorResponse = String(describing: responseDataJson["message"])
                    }
                    
                    let error = APIError.StatusResponse(status: status, message: errorResponse)
                    Log.error(error.debugDescription, tags: error.debugTags)
                    completion((nil, nil, error))
                    return
                }
                
                if let urlString = response?.url?.absoluteString {
                    let responseTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                    Log.debug("Request completed: \(urlString), response time: \(responseTime) ms", tags:["request"])
                }
                completion((data, response, error))
            }
        }.resume()
    }
    
    func createConfigRequest(user: DevCycleUser, enableEdgeDB: Bool, extraParams: RequestParams? = nil) -> URLRequest {
        var userQueryItems: [URLQueryItem] = user.toQueryItems()
        let queryItem = URLQueryItem(name: "enableEdgeDB", value: String(enableEdgeDB))
        userQueryItems.append(queryItem)
        if let extraParams = extraParams {
            if (extraParams.sse) {
                userQueryItems.append(URLQueryItem(name: "sse", value: "1"))
            }
            if let lastModified = extraParams.lastModified {
                userQueryItems.append(URLQueryItem(name: "sseLastModified", value: String(lastModified)))
            }
            if let etag = extraParams.etag {
                userQueryItems.append(URLQueryItem(name: "sseEtag", value: etag))
            }
        }
        var urlComponents: URLComponents = createRequestUrl(type: "config", userQueryItems)
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        let url = urlComponents.url!
        return URLRequest(url: url)
    }

    func createEventsRequest() -> URLRequest {
        let urlComponents: URLComponents = createRequestUrl(type: "event")
        let url = urlComponents.url!
        return URLRequest(url: url)
    }
    
    func createSaveEntityRequest() -> URLRequest {
        let urlComponents: URLComponents = createRequestUrl(type: "edgeDB")
        let url = urlComponents.url!
        return URLRequest(url: url)
    }
    
    private func createRequestUrl(type: String, _ queryItems: [URLQueryItem] = []) -> URLComponents {
        var url: String
        var querySpecificItems: [URLQueryItem] = queryItems
        
        switch(type) {
        case "event":
            if let proxyUrl = self.options?.eventsApiProxyURL {
                url = proxyUrl
            } else {
                url = NetworkingConstants.eventsUrl + NetworkingConstants.hostUrl
            }
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.events)")
        case "edgeDB":
            if let proxyUrl = self.options?.apiProxyURL {
                url = proxyUrl
            } else {
                url = NetworkingConstants.sdkUrl + NetworkingConstants.hostUrl
            }
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.edgeDB)")
            if let userId = config.user.userId {
                url.append("/\(userId)")
            }
        default:
            if let proxyUrl = self.options?.apiProxyURL {
                url = proxyUrl
            } else {
                url = NetworkingConstants.sdkUrl + NetworkingConstants.hostUrl
            }
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.config)")
            querySpecificItems.append(URLQueryItem(name: "sdkKey", value: config.sdkKey))
        }
        var urlComponents: URLComponents = URLComponents(string: url)!
        if (!querySpecificItems.isEmpty) {
            urlComponents.queryItems = querySpecificItems
        }
        return urlComponents
    }
    
    private func generateEventPayload(_ events: [DevCycleEvent], _ userId: String, _ featureVariables: [String:String]?) -> [[String:Any]] {
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
                "featureVars": featureVariables ?? [:]
            ]

            if (event.target != nil) { eventToPost["target"] = event.target }
            if (event.value != nil) { eventToPost["value"] = event.value }
            if (event.metaData != nil) { eventToPost["metaData"] = event.metaData }
            if (event.type != "variableDefaulted" && event.type != "variableEvaluated") {
                eventToPost["customType"] = event.type
                eventToPost["type"] = "customEvent"
            }
            
            eventsJSON.append(eventToPost)
        }

        return eventsJSON
    }

    private func sendEventsPayload(events: [[String:Any]], user: Any, completion: @escaping PublishEventsCompletionHandler) {
        var eventsRequest = createEventsRequest()
        eventsRequest.httpMethod = "POST"
        eventsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        eventsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        eventsRequest.addValue(self.config.sdkKey, forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "events": events,
            "user": user
        ]

        let jsonBody = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
        Log.debug("Post Events Payload: \(String(data: jsonBody!, encoding: .utf8) ?? "")")
        eventsRequest.httpBody = jsonBody
        
        self.makeRequest(request: eventsRequest) { data, response, error in
            if error != nil || data == nil {
                return completion((data, response, error))
            }

            return completion((data, response, nil))
        }
    }
}
