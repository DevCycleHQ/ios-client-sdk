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
