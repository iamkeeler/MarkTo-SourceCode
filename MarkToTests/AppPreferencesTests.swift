import XCTest
import AppKit
import ServiceManagement
@testable import MarkTo

@MainActor
final class AppPreferencesTests: XCTestCase {

    private final class MockLoginItemService: LoginItemManaging {
        enum MockError: LocalizedError {
            case operationFailed

            var errorDescription: String? { "Mock login-item failure" }
        }

        var status: SMAppService.Status = .notRegistered
        var registerError: Error?
        var unregisterError: Error?
        private(set) var registerCallCount = 0
        private(set) var unregisterCallCount = 0

        func register() throws {
            registerCallCount += 1
            if let registerError { throw registerError }
            status = .enabled
        }

        func unregister() throws {
            unregisterCallCount += 1
            if let unregisterError { throw unregisterError }
            status = .notRegistered
        }
    }

    private func makeTestDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "com.attachdesign.markto.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    func testDefaultValues() {
        let (testUserDefaults, suiteName) = makeTestDefaults()
        defer { testUserDefaults.removePersistentDomain(forName: suiteName) }
        let prefs = AppPreferences(userDefaults: testUserDefaults, appliesSystemChanges: false)

        XCTAssertFalse(prefs.hideOnStartup, "hideOnStartup should default to false")
        XCTAssertFalse(prefs.hideDockIcon, "hideDockIcon should default to false")
        XCTAssertFalse(prefs.startAtLogin, "startAtLogin should default to false")
    }

    func testHideOnStartupPersistence() {
        let (testUserDefaults, suiteName) = makeTestDefaults()
        defer { testUserDefaults.removePersistentDomain(forName: suiteName) }
        let prefs = AppPreferences(userDefaults: testUserDefaults, appliesSystemChanges: false)

        XCTAssertFalse(prefs.hideOnStartup)

        // Toggle on
        prefs.hideOnStartup = true
        XCTAssertTrue(testUserDefaults.bool(forKey: AppPreferences.Keys.hideOnStartup), "UserDefaults should store true for hideOnStartup")

        // Reload in new instance
        let reloadedPrefs = AppPreferences(userDefaults: testUserDefaults, appliesSystemChanges: false)
        XCTAssertTrue(reloadedPrefs.hideOnStartup, "Reloaded AppPreferences should reflect saved hideOnStartup state")

        // Toggle off
        reloadedPrefs.hideOnStartup = false
        XCTAssertFalse(testUserDefaults.bool(forKey: AppPreferences.Keys.hideOnStartup), "UserDefaults should store false for hideOnStartup")
    }

    func testHideDockIconPersistence() {
        let (testUserDefaults, suiteName) = makeTestDefaults()
        defer { testUserDefaults.removePersistentDomain(forName: suiteName) }
        let prefs = AppPreferences(userDefaults: testUserDefaults, appliesSystemChanges: false)

        XCTAssertFalse(prefs.hideDockIcon)

        prefs.hideDockIcon = true
        XCTAssertTrue(testUserDefaults.bool(forKey: AppPreferences.Keys.hideDockIcon), "UserDefaults should store true for hideDockIcon")

        let reloadedPrefs = AppPreferences(userDefaults: testUserDefaults, appliesSystemChanges: false)
        XCTAssertTrue(reloadedPrefs.hideDockIcon, "Reloaded AppPreferences should reflect saved hideDockIcon state")
    }

    func testRefreshLoginItemStatusReconcilesSavedPreferenceWithoutRegistration() {
        let (testUserDefaults, suiteName) = makeTestDefaults()
        defer { testUserDefaults.removePersistentDomain(forName: suiteName) }
        testUserDefaults.set(true, forKey: AppPreferences.Keys.startAtLogin)
        let loginItemService = MockLoginItemService()
        let prefs = AppPreferences(
            userDefaults: testUserDefaults,
            loginItemService: loginItemService
        )

        prefs.refreshLoginItemStatus()

        XCTAssertFalse(prefs.startAtLogin)
        XCTAssertFalse(testUserDefaults.bool(forKey: AppPreferences.Keys.startAtLogin))
        XCTAssertEqual(loginItemService.unregisterCallCount, 0)
    }

    func testLoginItemRegistrationFailureRollsBackAndReportsError() {
        let (testUserDefaults, suiteName) = makeTestDefaults()
        defer { testUserDefaults.removePersistentDomain(forName: suiteName) }
        let loginItemService = MockLoginItemService()
        loginItemService.registerError = MockLoginItemService.MockError.operationFailed
        let prefs = AppPreferences(
            userDefaults: testUserDefaults,
            loginItemService: loginItemService
        )

        prefs.startAtLogin = true

        XCTAssertFalse(prefs.startAtLogin)
        XCTAssertFalse(testUserDefaults.bool(forKey: AppPreferences.Keys.startAtLogin))
        XCTAssertEqual(loginItemService.registerCallCount, 1)
        XCTAssertTrue(prefs.loginItemMessage?.contains("Mock login-item failure") == true)
    }

    func testLoginItemRequiresApprovalRollsBackAndProvidesInstructions() {
        let (testUserDefaults, suiteName) = makeTestDefaults()
        defer { testUserDefaults.removePersistentDomain(forName: suiteName) }
        let loginItemService = MockLoginItemService()
        loginItemService.status = .requiresApproval
        let prefs = AppPreferences(
            userDefaults: testUserDefaults,
            loginItemService: loginItemService
        )

        prefs.refreshLoginItemStatus()

        XCTAssertFalse(prefs.startAtLogin)
        XCTAssertTrue(prefs.loginItemMessage?.contains("System Settings") == true)
    }

    func testAppDelegateTerminationBehavior() {
        let appDelegate = AppDelegate()
        let shouldTerminate = appDelegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared)

        XCTAssertFalse(shouldTerminate, "App should not terminate when last window is closed so menu bar item persists")
    }

    func testDynamicVersionFormatting() {
        // Test version formatting helper with mock dictionary
        func formatVersion(from dict: [String: Any]?) -> String {
            let version = dict?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            let build = dict?["CFBundleVersion"] as? String ?? ""
            return build.isEmpty ? version : "\(version) (\(build))"
        }

        // Full info dictionary
        let fullDict: [String: Any] = [
            "CFBundleShortVersionString": "1.0.3",
            "CFBundleVersion": "12"
        ]
        XCTAssertEqual(formatVersion(from: fullDict), "1.0.3 (12)")

        // Missing build number
        let noBuildDict: [String: Any] = [
            "CFBundleShortVersionString": "1.0.2"
        ]
        XCTAssertEqual(formatVersion(from: noBuildDict), "1.0.2")

        // Empty dictionary fallback
        XCTAssertEqual(formatVersion(from: [:]), "1.0.0")

        // Nil dictionary fallback
        XCTAssertEqual(formatVersion(from: nil), "1.0.0")
    }
}
