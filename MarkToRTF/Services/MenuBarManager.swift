import Foundation
import AppKit
import SwiftUI

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "MarkToRTF")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup context menu for right-click
        setupContextMenu()
    }
    
    private func setupContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MarkToRTF", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set targets for menu items
        for item in menu.items {
            item.target = self
        }
        
        statusItem?.menu = menu
    }
    
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click: show context menu (handled automatically by statusItem.menu)
            return
        } else {
            // Left-click: show main window
            showMainWindow()
        }
    }
    
    @objc private func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        for window in NSApplication.shared.windows {
            if window.contentViewController is NSHostingController<ContentView> {
                window.makeKeyAndOrderFront(self)
                return
            }
        }
        
        // If no window exists, create one
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "MarkToRTF"
        window.setContentSize(NSSize(width: 400, height: 350))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.makeKeyAndOrderFront(self)
    }
    
    @objc private func showSettings() {
        NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        statusItem = nil
    }
}
