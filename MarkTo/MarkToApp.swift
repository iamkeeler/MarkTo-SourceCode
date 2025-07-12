import SwiftUI

@main
struct MarkToApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var appDelegate = AppDelegate()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("MarkTo")
                .frame(width: 420, height: 380)
        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, ObservableObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Allow app to show in dock and be activated normally
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show window when dock icon is clicked
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}
