//
//  AppDelegate.swift
//  DevCycle-MacOS-Example-App
//

import Cocoa
import DevCycle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    override init() {
        super.init()
        do {
            // TODO: Set SDK Key in DevCycleManager.swift

            // Insert code here to initialize your application
            // create anonymous user
            let user = try DevCycleUser.builder()
                .isAnonymous(true)
                .build()
            
            // Initialize DevCycle
            DevCycleManager.shared.initialize(user: user)
        } catch {
            fatalError("Failed to build DevCycleUser: \(error)")
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // No DevCycle initialization needed here
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}
