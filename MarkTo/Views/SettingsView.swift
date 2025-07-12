import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    
    var body: some View {
        Form {
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
        .frame(width: 500, height: 450)
    }
}

#Preview {
    SettingsView()
}
