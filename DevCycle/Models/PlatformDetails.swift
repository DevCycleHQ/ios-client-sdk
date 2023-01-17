//
//  PlatformDetails.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#endif

struct PlatformDetails {
    #if os(iOS)
    var deviceModel: String { UIDevice.current.model }
    var systemVersion: String { UIDevice.current.systemVersion }
    var systemName: String { UIDevice.current.systemName }
    #elseif os(OSX)
    
    // TODO: figure out how to get this from macos: https://stackoverflow.com/questions/20070333/obtain-model-identifier-string-on-os-x
    var deviceModel = "model"
    var systemVersion: String { ProcessInfo.processInfo.operatingSystemVersionString }
    var systemName = "macos"
    #endif
    
    var sdkType = "mobile"
    var sdkVersion = "1.7.2"
}
