import Foundation
import AppKit
import ServiceManagement

// MARK: - App Settings Manager
@MainActor
class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    enum Keys {
        static let hideDockIcon = "hideDockIcon"
        static let startAtLogin = "startAtLogin"
        static let hideOnStartup = "hideOnStartup"
    }

    @Published var hideDockIcon: Bool {
        didSet {
            saveSettings()
            if appliesSystemChanges {
                updateDockIconVisibility()
            }
        }
    }

    @Published var startAtLogin: Bool {
        didSet {
            saveSettings()
            if appliesSystemChanges {
                updateLoginItem()
            }
        }
    }

    @Published var hideOnStartup: Bool {
        didSet {
            saveSettings()
        }
    }

    private let userDefaults: UserDefaults
    private let appliesSystemChanges: Bool

    // Bundle identifier for login item
    private let bundleIdentifier = "com.attachdesign.markto"

    init(userDefaults: UserDefaults = .standard, appliesSystemChanges: Bool = true) {
        self.userDefaults = userDefaults
        self.appliesSystemChanges = appliesSystemChanges

        // Load saved settings
        hideDockIcon = userDefaults.bool(forKey: Keys.hideDockIcon)
        startAtLogin = userDefaults.bool(forKey: Keys.startAtLogin)
        hideOnStartup = userDefaults.bool(forKey: Keys.hideOnStartup)
    }

    private func saveSettings() {
        userDefaults.set(hideDockIcon, forKey: Keys.hideDockIcon)
        userDefaults.set(startAtLogin, forKey: Keys.startAtLogin)
        userDefaults.set(hideOnStartup, forKey: Keys.hideOnStartup)
    }

    func applyDockIconVisibility() {
        updateDockIconVisibility()
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
