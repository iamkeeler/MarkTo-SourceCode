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

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        Form {
            // MARK: - Appearance Section
            Section {
                // Theme Selection
                LabeledContent("Appearance") {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(AppTheme.allCases) { theme in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        themeManager.currentTheme = theme
                                    }
                                } label: {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.displayName)
                                                .font(.body)
                                            Text(theme.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    } icon: {
                                        Image(systemName: theme.systemImage)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: themeManager.currentTheme.systemImage)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                                
                                Text(themeManager.currentTheme.displayName)
                                    .foregroundStyle(.primary)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.tertiary)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Choose your preferred appearance theme")
                    }
                }
                .help("Select between light, dark, or system appearance")
                
            } header: {
                Label("Appearance", systemImage: "paintbrush")
            } footer: {
                Text("Customize the visual appearance of MarkTo.")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                // Font Size Setting
                LabeledContent("Font Size") {
                    HStack(spacing: 8) {
                        Slider(value: $fontSize, in: 10...24, step: 1) {
                            Text("Font Size")
                        } minimumValueLabel: {
                            Text("10")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } maximumValueLabel: {
                            Text("24")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 120)
                        
                        Text("\(Int(fontSize))pt")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 30, alignment: .trailing)
                    }
                }
                .help("Adjust the editor font size")
                
                // Character Count Setting
                LabeledContent("Show Character Count") {
                    Toggle("Show Character Count", isOn: $showCharacterCount)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .help("Display character count in the editor")
                
            } header: {
                Label("Editor", systemImage: "textformat")
            } footer: {
                Text("Customize your editing experience.")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                // App Info
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Developer") {
                    Text("Attach.design")
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Copyright") {
                    Text("© 2025 Attach.design")
                        .foregroundStyle(.secondary)
                }
                
                // Privacy Policy Link
                LabeledContent("Privacy Policy") {
                    Button("View Policy") {
                        if let url = URL(string: "https://MarkTo.attach.design/privacy.html") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)
                }
                
            } header: {
                Label("About MarkTo", systemImage: "info.circle")
            } footer: {
                Text("A lightweight macOS app for converting Markdown to Rich Text Format.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(width: 500, height: 500)
    }
}

#Preview {
    SettingsView()
}
