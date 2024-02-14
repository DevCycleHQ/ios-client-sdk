//
//  SSEConnection.swift
//  DevCycle
//
//  Created by Adam Wootton on 2022-10-19.
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation
import LDSwiftEventSource

typealias LDEventHandler = LDSwiftEventSource.EventHandler

public typealias MessageHandler = (String) -> Void

protocol SSEConnectionProtocol {
    var connected: Bool { get }
    func openConnection()
    func close()
    func reopen()
}

class SSEConnection: SSEConnectionProtocol {
    private var connection: EventSource
    private var url: URL
    private var handler: MessageHandler
    
    var connected: Bool
    
    init(url: URL, eventHandler: @escaping MessageHandler) {
        self.url = url
        self.handler = eventHandler
        self.connected = false
        self.connection = SSEConnection.makeConnection(url: url, eventHandler: eventHandler)
        self.openConnection()
    }
    
    public func openConnection() {
        Log.debug("Establishing realtime streaming connection.")
        self.connection.start()
        self.connected = true
    }
    
    static func makeConnection(url: URL, eventHandler: @escaping MessageHandler) -> EventSource {
        return EventSource(config: EventSource.Config(
            handler: Handler(handler: eventHandler),
            url: url
        ))
    }
    
    public func close() {
        self.connection.stop()
        self.connected = false
    }
    
    public func reopen() {
        Log.debug("Re-establishing realtime streaming connection")
        self.close()
        self.connection = SSEConnection.makeConnection(url: self.url, eventHandler: self.handler)
        self.openConnection()
    }
    
    public func isConnected() -> Bool {
        return self.connected
    }
}

class Handler: LDEventHandler {
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
        guard let data = data.data(using: .utf8) else {
            throw SSEMessageError.initError("Failed to generate an NSData object from SSE data field")
        }
        guard let dataDictionary = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
            throw SSEMessageError.initError("Failed to parse data field in SSE message")
        }
        let etag = dataDictionary["etag"] as? String
        let type = dataDictionary["type"] as? String
        let lastModified = dataDictionary["lastModified"] as? Int
        self.data = Data(etag: etag, lastModified: lastModified, type: type)
    }
}
