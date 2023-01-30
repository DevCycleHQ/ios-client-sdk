//
//  ObjCErrors.swift
//  DevCycle
//
//

import Foundation

enum ObjCClientErrors: Error {
    case MissingSDKKey
    case MissingUser
    case InvalidUser
    case InvalidClient
}

public enum ObjCUserErrors: Error {
    case MissingUserId
    case MissingIsAnonymous
    case InvalidUser
}

public enum ObjCConfigErrors: Error {
    case EnvironmentMissing
    case FeatureVariationMapMissing
    case ProjectMissing
}

public enum ObjCEventErrors: Error {
    case MissingEventType
    case InvalidEvent
}
