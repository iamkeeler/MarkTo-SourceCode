import Foundation
import AppKit
import SwiftUI

// Custom window class that can become key and main
class PopoverWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

@MainActor
class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popoverWindow: NSWindow?
    private var settingsWindow: NSWindow?
    nonisolated(unsafe) private var globalClickMonitor: Any?
    nonisolated(unsafe) private var localClickMonitor: Any?
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click: show context menu
            showContextMenu()
        } else {
            // Left-click: toggle dropdown window
            toggleDropdownWindow()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MarkTo", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set targets for menu items
        for item in menu.items {
            item.target = self
        }
        
        guard let statusButton = statusItem?.button else { return }
        
        // Show the menu at the button location
        let buttonFrame = statusButton.frame
        let menuOrigin = NSPoint(x: buttonFrame.minX, y: buttonFrame.minY - 5)
        menu.popUp(positioning: nil, at: menuOrigin, in: statusButton)
    }
    
    private func toggleDropdownWindow() {
        if let window = popoverWindow, window.isVisible {
            closeDropdownWindow()
        } else {
            showDropdownWindow()
        }
    }
    
    private func closeDropdownWindow() {
        popoverWindow?.orderOut(self)
        popoverWindow = nil
        
        // Remove click monitors
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }
    
    private func showDropdownWindow() {
        guard let statusButton = statusItem?.button else { return }

        let windowSize = NSSize(width: 420, height: 410)
        let buttonFrame = statusButton.convert(statusButton.bounds, to: nil)
        let screenFrame = statusButton.window?.convertToScreen(buttonFrame) ?? .zero
        let visibleFrame = statusButton.window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let horizontalPadding: CGFloat = 8
        let desiredX = screenFrame.midX - windowSize.width / 2
        let minimumX = visibleFrame.minX + horizontalPadding
        let maximumX = visibleFrame.maxX - windowSize.width - horizontalPadding
        let originX = min(max(desiredX, minimumX), max(minimumX, maximumX))
        let maximumArrowOffset = windowSize.width / 2 - 24
        let arrowOffset = min(
            max(screenFrame.midX - (originX + windowSize.width / 2), -maximumArrowOffset),
            maximumArrowOffset
        )

        // Create the content view for dropdown
        let contentView = ContentView(
            isMenuBar: true,
            onOpenSettings: { [weak self] in
                self?.closeDropdownWindow()
                self?.showSettings()
            },
            popoverArrowOffset: arrowOffset
        )
        .environmentObject(AppPreferences.shared)
        let hostingController = NSHostingController(rootView: contentView)
        
        // Create the dropdown window using our custom window class
        let window: NSWindow = PopoverWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.setContentSize(windowSize)
        
        // Configure window for user interaction
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false
        
        // Position the window below the status item with 4pt space for the upward uptick
        let windowOrigin = NSPoint(
            x: originX,
            y: screenFrame.minY - window.frame.height - 4
        )
        
        window.setFrameOrigin(windowOrigin)
        window.makeKeyAndOrderFront(self)
        
        // Activate the app to ensure the window can receive input
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Store reference to the window
        popoverWindow = window
        
        // Add observers to close window when clicking outside
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let window = self?.popoverWindow {
                let windowFrame = window.frame
                let globalClickLocation = NSEvent.mouseLocation
                
                if !windowFrame.contains(globalClickLocation) {
                    self?.closeDropdownWindow()
                }
            }
        }
        
        // Add local monitor to handle clicks inside the window
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            // Return the event to allow normal processing within the window
            return event
        }
    }
    
    @objc private func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        for window in NSApplication.shared.windows {
            if !(window is PopoverWindow) && window != settingsWindow && window.title == "MarkTo" {
                window.makeKeyAndOrderFront(self)
                return
            }
        }
        
        // If no window exists, create one with navigation support
        let contentView = ContentView()
            .navigationTitle("MarkTo")
            .environmentObject(AppPreferences.shared)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "MarkTo"
        window.setContentSize(NSSize(width: 420, height: 380))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        window.makeKeyAndOrderFront(self)
    }
    
    @objc private func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(AppPreferences.shared)
            let hostingController = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            settingsWindow?.title = "Settings"
            settingsWindow?.contentViewController = hostingController
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.minSize = NSSize(width: 500, height: 600)
            settingsWindow?.center()
            
            // Apply subtle glass styling while keeping the titlebar functional
            settingsWindow?.titlebarAppearsTransparent = false
            settingsWindow?.backgroundColor = NSColor.windowBackgroundColor
            settingsWindow?.isOpaque = true
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openSettings() {
        showSettings()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
