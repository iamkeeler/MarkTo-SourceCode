import SwiftUI
import AppKit

@main
struct MarkToApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var appSettings = AppPreferences.shared

    var body: some Scene {
        WindowGroup {
            ContentView(onOpenSettings: {
                menuBarManager.openSettings()
            })
                .navigationTitle("MarkTo")
                .frame(width: 420, height: 380)
                .environmentObject(appSettings)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(appSettings)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply initial dock icon visibility
        AppPreferences.shared.applyDockIconVisibility()

        // If hide on startup is enabled, hide non-popover windows on launch
        if AppPreferences.shared.hideOnStartup {
            DispatchQueue.main.async {
                for window in NSApplication.shared.windows where !(window is PopoverWindow) {
                    window.orderOut(nil)
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show window when dock icon or application is clicked/reopened
        if !flag {
            for window in sender.windows where !(window is PopoverWindow) {
                window.makeKeyAndOrderFront(self)
                return true
            }
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in menu bar even if window is closed
        return false
    }
}
