//
//  PlatformDetails.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import IOKit
#endif

struct PlatformDetails {
    #if os(iOS) || os(tvOS)
    var deviceModel = getDeviceModel()
    var systemVersion: String { UIDevice.current.systemVersion }
    var systemName: String { UIDevice.current.systemName }
    #elseif os(watchOS)
    var deviceModel = getDeviceModel()
    var systemVersion: String { WKInterfaceDevice.current().systemVersion }
    var systemName: String { WKInterfaceDevice.current().systemName }
    #elseif os(macOS)
    var deviceModel = getMacOSModelIdentifier()
    var systemVersion = getMacOSVersion()
    var systemName = "macOS"
    #endif
    
    var sdkType = "mobile"
    var sdkVersion = "1.16.0"
}

#if os(macOS)
func getMacOSVersion() -> String {
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
}

func getMacOSModelIdentifier() -> String {
    let service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                              IOServiceMatching("IOPlatformExpertDevice"))
    var modelIdentifier: String?
    if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
        modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
    }

    IOObjectRelease(service)
    if let modelId = modelIdentifier {
        return modelId
    } else {
        return "unknown macos"
    }
}
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
func getDeviceModel() -> String {
    if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return "Simulator " + simulatorModelIdentifier
    }
    var sysinfo = utsname()
    uname(&sysinfo) // ignore return value
    return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
}
#endif
