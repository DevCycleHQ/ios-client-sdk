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

    func queue(request: URLRequest, user: DevCycleUser, callback: @escaping ConfigCompletionHandler)
    {
        if self.requestInFlight {
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
            if self.requestCallbacks.isEmpty {
                guard let config = processConfig(response.data) else {
                    callback((nil, response.error))
                    return
                }

                self.cacheService.saveConfig(user: user, configToSave: response.data)
                self.requestInFlight = false
                callback((config, response.error))
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

    func makeLastRequestInQueue(user: DevCycleUser, complete: (() -> Void)?) {
        guard let lastRequest = self.requestCallbacks.last?.request else {
            Log.debug("No last request to make in queue")
            return
        }
        service.makeRequest(request: lastRequest) { response in
            for requestCallback in self.requestCallbacks {
                guard let config = processConfig(response.data) else {
                    requestCallback.callback((nil, response.error))
                    return
                }

                self.cacheService.saveConfig(user: user, configToSave: response.data)
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
