//
//  AppDelegate.swift
//  DevCycle-MacOS-Example-App
//

import Cocoa
import DevCycle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // create anonymous user
        let user = try? DVCUser.builder()
                               .isAnonymous(true)
                               .build()
        
        // initialize DevCycle
        if let user = user {
            DevCycleManager.shared.initialize(user: user)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}
