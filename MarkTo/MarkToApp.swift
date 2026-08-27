import SwiftUI
import AppKit

extension Notification.Name {
    static let markdownFileConversionCompleted = Notification.Name("markdownFileConversionCompleted")
}

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
        AppPreferences.shared.refreshLoginItemStatus()

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

    func application(_ application: NSApplication, open urls: [URL]) {
        convertMarkdownDocuments(at: urls)
    }

    func application(_ application: NSApplication, openFiles filenames: [String]) {
        convertMarkdownDocuments(at: filenames.map(URL.init(fileURLWithPath:)))
    }

    private func convertMarkdownDocuments(at urls: [URL]) {
        let markdownURLs = urls.filter(MarkdownFileConverter.supports)
        guard !markdownURLs.isEmpty else { return }

        let converter = MarkdownFileConverter(
            formatting: FormattingPreferences.shared.snapshot()
        )

        Task { @MainActor in
            for url in markdownURLs {
                let result = await Task.detached(priority: .userInitiated) {
                    converter.convertFile(at: url)
                }.value

                NotificationCenter.default.post(
                    name: .markdownFileConversionCompleted,
                    object: nil,
                    userInfo: ["result": result]
                )
            }
        }
    }
}
