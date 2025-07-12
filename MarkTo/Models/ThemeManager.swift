import SwiftUI
import AppKit

// MARK: - Theme Options
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var systemImage: String {
        switch self {
        case .system:
            return "laptopcomputer"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
    
    var description: String {
        switch self {
        case .system:
            return "Follow system appearance"
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        }
    }
    
    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil // Let system decide
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
            applyTheme()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    init() {
        // Load saved theme or default to system
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .system
        }
        
        // Apply theme on initialization
        applyTheme()
    }
    
    private func saveTheme() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    private func applyTheme() {
        // Apply to all windows
        for window in NSApplication.shared.windows {
            window.appearance = currentTheme.nsAppearance
        }
        
        // Set application appearance
        NSApplication.shared.appearance = currentTheme.nsAppearance
    }
    
    // Method to apply theme to a specific window
    func applyTheme(to window: NSWindow) {
        window.appearance = currentTheme.nsAppearance
    }
}
