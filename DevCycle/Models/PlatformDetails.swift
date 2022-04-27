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
    #endif
    
    var sdkType = "mobile"
    var sdkVersion = "1.2.1"
}
