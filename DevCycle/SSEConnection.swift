//
//  SSEConnection.swift
//  DevCycle
//
//  Created by Adam Wootton on 2022-10-19.
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation
import LDSwiftEventSource

public typealias MessageHandler = (String) -> Void

class SSEConnection {
    private var connection: EventSource
    
    init(url: URL, eventHandler: @escaping MessageHandler) {
        Log.debug("Establishing realtime streaming connection.")
        let handler = Handler(handler: eventHandler)
        self.connection = EventSource(config: EventSource.Config(
            handler: handler,
            url: url
        ))
        self.connection.start()
    }
    
    public func close() {
        self.connection.stop()
    }
}

class Handler: EventHandler {
    private var handler: MessageHandler
    
    init(handler: @escaping MessageHandler) {
        self.handler = handler
    }
    
    func onOpened() {
        Log.debug("Streaming connection opened.")
    }
    
    func onClosed() {
        Log.debug("Streaming connection closed.")
    }
    
    func onMessage(eventType: String, messageEvent: LDSwiftEventSource.MessageEvent) {
        self.handler(messageEvent.data)
    }
    
    func onComment(comment: String) {
        
    }
    
    func onError(error: Error) {
        Log.error("Streaming connection had an error: " + error.localizedDescription)
    }
}

public struct SSEMessage {
    enum SSEMessageError: Error, Equatable {
        case initError(String)
    }
    struct Data {
        var etag: String?
        var lastModified: Int?
        var type: String?
    }

    var data: Data

    init(from dictionary: [String: Any]) throws {
        guard let data = dictionary["data"] as? String else {
            throw SSEMessageError.initError("No data field in SSE JSON")
        }
        guard let dataDictionary = try? JSONSerialization.jsonObject(with: (data.data(using: .utf8))!, options: .fragmentsAllowed) as? [String: Any] else {
            throw SSEMessageError.initError("Failed to parse data field in SSE message")
        }
        let etag = dataDictionary["etag"] as? String
        let type = dataDictionary["type"] as? String
        let lastModified = dataDictionary["lastModified"] as? Int
        self.data = Data(etag: etag, lastModified: lastModified, type: type)
    }
}
