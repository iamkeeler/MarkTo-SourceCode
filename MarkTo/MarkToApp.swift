import SwiftUI
import AppKit

@main
struct MarkToApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var appDelegate = AppDelegate()
    @StateObject private var appSettings = AppPreferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("MarkTo")
                .frame(width: 420, height: 380)
        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(appSettings)
        }
    }
}

class AppDelegate: NSObject, ObservableObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initial dock icon setting will be handled by AppSettings
        // Default to .regular unless specifically set to hide
        let hideDockIcon = UserDefaults.standard.bool(forKey: "hideDockIcon")
        if hideDockIcon {
            NSApplication.shared.setActivationPolicy(.accessory)
        } else {
            NSApplication.shared.setActivationPolicy(.regular)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show window when dock icon is clicked (if dock icon is visible)
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}
