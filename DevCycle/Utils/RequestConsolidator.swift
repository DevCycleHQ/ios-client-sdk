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
    
    init(service: DevCycleServiceProtocol) {
        self.service = service
        self.requestCallbacks = []
    }
    
    func queue(request: URLRequest, callback: @escaping ConfigCompletionHandler) {
        let configComplete: ConfigCompletionHandler = { config in
            if let lastRequestCallback = self.requestCallbacks.last, lastRequestCallback.request == request {
                for requestCallback in self.requestCallbacks {
                    requestCallback.callback(config)
                }
                self.requestCallbacks = []
            }
        }
        self.requestCallbacks.append(
            RequestWithCallback(
                callback: callback,
                request: request,
                service: self.service,
                finish: configComplete
            )
        )
    }
}

class RequestWithCallback {
    var callback: ConfigCompletionHandler
    var request: URLRequest
    init(callback: @escaping ConfigCompletionHandler, request: URLRequest, service: DevCycleServiceProtocol, finish: @escaping ConfigCompletionHandler) {
        self.callback = callback
        self.request = request
        service.makeRequest(request: request) { response in
            guard let config = processConfig(response.data) else {
                finish((nil, response.error))
                return
            }
            finish((config, response.error))
        }
    }
}
