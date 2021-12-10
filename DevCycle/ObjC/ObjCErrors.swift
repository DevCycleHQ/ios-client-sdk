//
//  ObjCErrors.swift
//  DevCycle
//
//

import Foundation

enum ObjCClientErrors: Error {
    case MissingEnvironmentKey
    case MissingUser
    case InvalidUser
    case InvalidClient
}

public enum ObjCUserErrors: Error {
    case MissingUserId
    case MissingIsAnonymous
    case InvalidUser
}
