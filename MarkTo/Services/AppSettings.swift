import Foundation
import AppKit
import ServiceManagement

// MARK: - App Settings Manager
@MainActor
class AppPreferences: ObservableObject {
    @Published var hideDockIcon: Bool {
        didSet {
            saveSettings()
            updateDockIconVisibility()
        }
    }
    
    @Published var startAtLogin: Bool {
        didSet {
            saveSettings()
            updateLoginItem()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let hideDockIconKey = "hideDockIcon"
    private let startAtLoginKey = "startAtLogin"
    
    // Bundle identifier for login item
    private let bundleIdentifier = "com.attachdesign.markto"
    
    init() {
        // Load saved settings
        hideDockIcon = userDefaults.bool(forKey: hideDockIconKey)
        startAtLogin = userDefaults.bool(forKey: startAtLoginKey)
        
        // Apply settings on initialization
        updateDockIconVisibility()
        updateLoginItem()
    }
    
    private func saveSettings() {
        userDefaults.set(hideDockIcon, forKey: hideDockIconKey)
        userDefaults.set(startAtLogin, forKey: startAtLoginKey)
    }
    
    private func updateDockIconVisibility() {
        if hideDockIcon {
            NSApplication.shared.setActivationPolicy(.accessory)
        } else {
            NSApplication.shared.setActivationPolicy(.regular)
        }
    }
    
    private func updateLoginItem() {
        do {
            if startAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
    
    // Check if app is currently set to start at login
    func checkLoginItemStatus() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    // Refresh the start at login setting from the system
    func refreshLoginItemStatus() {
        let systemStatus = checkLoginItemStatus()
        if systemStatus != startAtLogin {
            startAtLogin = systemStatus
        }
    }
}
