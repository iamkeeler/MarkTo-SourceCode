import XCTest
import AppKit

final class MarkToUITests: XCTestCase {
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hideOnStartup", "NO",
            "-hideDockIcon", "NO"
        ]
        app.launch()
        return app
    }

    @MainActor
    func testLaunchDoesNotReadClipboard() throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("# Clipboard content must stay private", forType: .string)
        defer { pasteboard.clearContents() }

        let app = launchApp()
        let window = app.windows["MarkTo"]
        XCTAssertTrue(window.waitForExistence(timeout: 3.0))

        let textEditor = window.textViews["Markdown input text editor"]
        XCTAssertTrue(textEditor.exists)
        XCTAssertEqual(textEditor.value as? String, "", "Launching MarkTo must not read clipboard content")
    }

    @MainActor
    func testMainWindowUIElements() throws {
        let app = launchApp()
        let window = app.windows["MarkTo"]
        let windowAppeared = window.waitForExistence(timeout: 3.0)
        XCTAssertTrue(windowAppeared, "Main window should appear on launch")

        let textEditor = window.textViews["Markdown input text editor"]
        let textEditorExists = textEditor.exists
        XCTAssertTrue(textEditorExists, "Markdown TextEditor should be present")

        let convertButton = window.buttons["Convert markdown to RTF and copy to clipboard"]
        let convertButtonExists = convertButton.exists
        let convertButtonEnabled = convertButton.isEnabled
        XCTAssertTrue(convertButtonExists, "Convert button should be present")
        XCTAssertFalse(convertButtonEnabled, "Convert button should be disabled when editor is empty")

        let settingsButton = window.buttons["openSettingsButton"]
        let settingsButtonExists = settingsButton.exists
        XCTAssertTrue(settingsButtonExists, "Settings button should be present")
        settingsButton.click()

        let settingsWindow = app.windows["Settings"]
        let settingsAppeared = settingsWindow.waitForExistence(timeout: 3.0)
        XCTAssertTrue(settingsAppeared, "Settings should open from the main-window gear button")
    }

    @MainActor
    func testMarkdownInputAndConversion() throws {
        let app = launchApp()
        let window = app.windows["MarkTo"]
        let windowAppeared = window.waitForExistence(timeout: 3.0)
        XCTAssertTrue(windowAppeared)

        let textEditor = window.textViews["Markdown input text editor"]
        textEditor.click()
        textEditor.typeText("# Hello World\n\nThis is **bold** text.")

        let convertButton = window.buttons["Convert markdown to RTF and copy to clipboard"]
        let convertButtonEnabled = convertButton.isEnabled
        XCTAssertTrue(convertButtonEnabled, "Convert button should be enabled after entering text")
        convertButton.click()

        let statusPredicate = NSPredicate(format: "label BEGINSWITH 'Status:'")
        let statusElement = window.descendants(matching: .any).matching(statusPredicate).element
        let statusAppeared = statusElement.waitForExistence(timeout: 3.0)
        XCTAssertTrue(statusAppeared, "Success status message should appear after conversion")
    }

    @MainActor
    func testSettingsWindowAndNavigation() throws {
        let app = launchApp()
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows["Settings"]
        let settingsAppeared = settingsWindow.waitForExistence(timeout: 3.0)
        XCTAssertTrue(settingsAppeared, "Settings window should open")

        let settingsElements = settingsWindow.descendants(matching: .any)
        let hideDockSwitchExists = settingsElements["hideDockIconToggle"].exists
        let hideOnStartupSwitchExists = settingsElements["hideOnStartupToggle"].exists
        let startAtLoginSwitchExists = settingsElements["startAtLoginToggle"].exists
        XCTAssertTrue(hideDockSwitchExists, "Hide Dock Icon toggle should be present")
        XCTAssertTrue(hideOnStartupSwitchExists, "Hide on Startup toggle should be present")
        XCTAssertTrue(startAtLoginSwitchExists, "Start at Login toggle should be present")

        let customizeButton = settingsWindow.buttons["customizeFormattingButton"]
        if customizeButton.exists {
            customizeButton.click()

            let backButton = app.buttons["formattingBackButton"]
            let backButtonAppeared = backButton.waitForExistence(timeout: 2.0)
            XCTAssertTrue(backButtonAppeared, "Back button should appear in formatting view")
            backButton.click()
        }
    }
}
