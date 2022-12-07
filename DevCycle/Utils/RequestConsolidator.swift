//
//  RequestConsolidator.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

class RequestConsolidator {
    var requestCallbacks: [RequestWithCallback]
    var service: DevCycleServiceProtocol
    var requestInFlight: Bool
    private var cacheService: CacheServiceProtocol
    
    init(service: DevCycleServiceProtocol, cacheService: CacheServiceProtocol) {
        self.service = service
        self.requestCallbacks = []
        self.requestInFlight = false
        self.cacheService = cacheService
    }
    
    func queue(request: URLRequest, user: DVCUser, callback: @escaping ConfigCompletionHandler) {
        if (self.requestInFlight) {
            self.requestCallbacks.append(
                RequestWithCallback(
                    callback: callback,
                    request: request
                )
            )
            return
        }
        
        self.requestInFlight = true
        service.makeRequest(request: request) { response in
            if (self.requestCallbacks.isEmpty) {
                guard let config = processConfig(response.data) else {
                    callback((nil, response.error))
                    return
                }
                
                self.cacheService.saveConfig(user: user, fetchDate: Int(Date().timeIntervalSince1970), configToSave: response.data)
                callback((config, response.error))
                self.requestInFlight = false
            } else {
                self.requestCallbacks.insert(
                    RequestWithCallback(
                        callback: callback,
                        request: request
                    ),
                    at: 0
                )
                self.makeLastRequestInQueue(user: user) {
                    self.requestInFlight = false
                }
            }
        }
    }
    
    func makeLastRequestInQueue(user: DVCUser, complete: (() -> Void)?) {
        guard let lastRequest = self.requestCallbacks.last?.request else {
            print("No last request to make in queue")
            return
        }
        service.makeRequest(request: lastRequest) { response in
            for requestCallback in self.requestCallbacks {
                guard let config = processConfig(response.data) else {
                    requestCallback.callback((nil, response.error))
                    return
                }
                
                self.cacheService.saveConfig(user: user, fetchDate: Int(Date().timeIntervalSince1970), configToSave: response.data)
                requestCallback.callback((config, response.error))
            }
            self.requestCallbacks = []
            complete?()
        }
    }
}

struct RequestWithCallback {
    var callback: ConfigCompletionHandler
    var request: URLRequest
    init(callback: @escaping ConfigCompletionHandler, request: URLRequest) {
        self.callback = callback
        self.request = request
    }
}
