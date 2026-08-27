import Foundation
import AppKit
import ServiceManagement

protocol LoginItemManaging: AnyObject {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LoginItemManaging {}

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
            if appliesSystemChanges && !isSynchronizingLoginItemStatus {
                updateLoginItem()
            }
        }
    }

    @Published var hideOnStartup: Bool {
        didSet {
            saveSettings()
        }
    }

    @Published private(set) var loginItemMessage: String?

    private let userDefaults: UserDefaults
    private let appliesSystemChanges: Bool
    private let loginItemService: any LoginItemManaging
    private var isSynchronizingLoginItemStatus = false

    init(
        userDefaults: UserDefaults = .standard,
        appliesSystemChanges: Bool = true,
        loginItemService: any LoginItemManaging = SMAppService.mainApp
    ) {
        self.userDefaults = userDefaults
        self.appliesSystemChanges = appliesSystemChanges
        self.loginItemService = loginItemService

        // Load saved settings
        hideDockIcon = userDefaults.bool(forKey: Keys.hideDockIcon)
        startAtLogin = userDefaults.bool(forKey: Keys.startAtLogin)
        hideOnStartup = userDefaults.bool(forKey: Keys.hideOnStartup)
        loginItemMessage = nil
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
        let requestedState = startAtLogin

        do {
            if requestedState {
                try loginItemService.register()
            } else {
                try loginItemService.unregister()
            }

            synchronizeLoginItemStatus()
            if startAtLogin != requestedState && loginItemMessage == nil {
                loginItemMessage = requestedState
                    ? "macOS did not enable Start at Login. Check System Settings › General › Login Items."
                    : "macOS did not disable Start at Login. Check System Settings › General › Login Items."
            }
        } catch {
            synchronizeLoginItemStatus()
            let action = requestedState ? "enable" : "disable"
            loginItemMessage = "Couldn’t \(action) Start at Login: \(error.localizedDescription)"
        }
    }

    // Check if app is currently set to start at login
    func checkLoginItemStatus() -> Bool {
        loginItemService.status == .enabled
    }

    // Refresh the start at login setting from the system
    func refreshLoginItemStatus() {
        synchronizeLoginItemStatus()
    }

    private func synchronizeLoginItemStatus() {
        let status = loginItemService.status
        let systemState = status == .enabled

        if systemState != startAtLogin {
            isSynchronizingLoginItemStatus = true
            startAtLogin = systemState
            isSynchronizingLoginItemStatus = false
        }

        switch status {
        case .enabled, .notRegistered:
            loginItemMessage = nil
        case .requiresApproval:
            loginItemMessage = "Allow MarkTo in System Settings › General › Login Items to start it automatically."
        case .notFound:
            loginItemMessage = "macOS could not locate MarkTo’s login item. Move MarkTo to Applications and try again."
        @unknown default:
            loginItemMessage = "macOS reported an unknown Start at Login status. Check System Settings › General › Login Items."
        }
    }
}
