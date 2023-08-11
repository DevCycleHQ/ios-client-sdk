//
//  EventEmitter.swift
//  DevCycle
//

public typealias EventHandler = (Any?) -> Void

public typealias SubscribeErrorHandler = (Error) -> Void
public typealias SubscribeInitializedHandler = (Bool) -> Void

public struct SubscribeError {
    // Had to add this index field, because I can't make this struct Equitable to do a equality comparison
    // because you can't compare anon function pointers... so it was either this or generate a UUID to compare.
    fileprivate var index: Int?
    var handler: SubscribeErrorHandler
    let key = "error"
    
    
    public init(_ handler: @escaping SubscribeErrorHandler) {
        self.handler = handler
    }
}

public struct SubscribeInitialized {
    fileprivate var index: Int?
    var handler: SubscribeInitializedHandler
    let key = "initialized"
    
    public init(_ handler: @escaping SubscribeInitializedHandler) {
        self.handler = handler
    }
}

public enum SubscribeHandlers {
    case error(SubscribeError)
    case initialized(SubscribeInitialized)
}

class EventEmitter {
    var errorHandlers: [SubscribeError] = []
    var initHandlers: [SubscribeInitialized] = []
    
    func subscribe(_ handler: SubscribeHandlers) {
        switch handler {
        case .error(var errorHandler):
            self.errorHandlers.append(errorHandler)
            errorHandler.index = self.errorHandlers.count-1
            break
        case .initialized(var initHandler):
            self.initHandlers.append(initHandler)
            initHandler.index = self.initHandlers.count-1
            break
        }
    }
    
    func unsubscribe(_ handler: SubscribeHandlers) {
        switch handler {
        case .error(let errorHandler):
            if let index = errorHandler.index {
                self.errorHandlers.remove(at: index)
            }
            break
        case .initialized(let initHandler):
            if let index = initHandler.index {
                self.initHandlers.remove(at: index)
            }
            break
        }
    }
    
    func emitError(_ err: Error) {
        self.errorHandlers.forEach { errSub in
            errSub.handler(err)
        }
    }
    
    func emitInitialized(_ success: Bool) {
        self.initHandlers.forEach { initSub in
            initSub.handler(success)
        }
    }
}
