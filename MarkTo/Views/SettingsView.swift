import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    @StateObject private var themeManager = ThemeManager()
    @EnvironmentObject private var appSettings: AppPreferences
    @State private var navigationPath = NavigationPath()

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                // MARK: - App Behavior Section
                Section {
                    // Hide Dock Icon Setting
                    LabeledContent("Hide Dock Icon") {
                        Toggle("Hide Dock Icon", isOn: $appSettings.hideDockIcon)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .accessibilityLabel("Hide Dock Icon")
                            .accessibilityIdentifier("hideDockIconToggle")
                    }
                    .help("Hide MarkTo from the Dock (app will still be accessible from menu bar)")

                    // Hide on Startup Setting
                    LabeledContent("Hide on Startup") {
                        Toggle("Hide on Startup", isOn: $appSettings.hideOnStartup)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .accessibilityLabel("Hide on Startup")
                            .accessibilityIdentifier("hideOnStartupToggle")
                    }
                    .help("Start MarkTo in the background without showing the main window")

                    // Start at Login Setting
                    LabeledContent("Start at Login") {
                        Toggle("Start at Login", isOn: $appSettings.startAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .accessibilityLabel("Start at Login")
                            .accessibilityIdentifier("startAtLoginToggle")
                    }
                    .help("Automatically start MarkTo when you log in to your Mac")

                } header: {
                    Label("App Behavior", systemImage: "gear")
                } footer: {
                    Text("Configure how MarkTo behaves on your system.")
                        .foregroundStyle(.secondary)
                }

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

                    // Rich Text Formatting Navigation
                    Button {
                        navigationPath.append("formatting")
                    } label: {
                        Label("Customize Formatting", systemImage: "textformat.abc")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .help("Customize font sizes and formatting for different markdown elements")
                    .accessibilityIdentifier("customizeFormattingButton")

                } header: {
                    Label("Editor", systemImage: "textformat")
                } footer: {
                    Text("Customize your editing experience and rich text output formatting.")
                        .foregroundStyle(.secondary)
                }

                Section {
                    // App Info
                    LabeledContent("Version") {
                        Text(appVersion)
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

                Section {
                    // Open Source Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MarkTo is open source software")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("This application is released under the Creative Commons Attribution-NonCommercial 4.0 International License. You are free to use, modify, and share the source code for non-commercial purposes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)

                    // GitHub Repository Link
                    LabeledContent("Source Code") {
                        Button("View on GitHub") {
                            if let url = URL(string: "https://github.com/iamkeeler/MarkTo-SourceCode") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                    .help("View the complete source code on GitHub")

                    // License Link
                    LabeledContent("License") {
                        Button("CC BY-NC 4.0") {
                            if let url = URL(string: "https://creativecommons.org/licenses/by-nc/4.0/") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                    .help("View the full license terms")

                    // Contributing Link
                    LabeledContent("Contributing") {
                        Button("Contribute") {
                            if let url = URL(string: "https://github.com/iamkeeler/MarkTo-SourceCode/blob/main/CONTRIBUTING.md") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                    .help("Learn how to contribute to the project")

                } header: {
                    Label("Open Source", systemImage: "chevron.left.forwardslash.chevron.right")
                } footer: {
                    Text("MarkTo is built with transparency and community collaboration in mind. Commercial licensing is available for business use.")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .frame(width: 500, height: 600)
            .navigationDestination(for: String.self) { destination in
                if destination == "formatting" {
                    FormattingCustomizationView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppPreferences.shared)
}
