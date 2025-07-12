import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Customize your MarkTo experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .background(Color(NSColor.controlBackgroundColor), in: Rectangle())
            
            ScrollView {
                VStack(spacing: 20) {
                    // Editor Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Editor", systemImage: "textformat")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Font Size")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Adjust the editor font size")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Text("\(Int(fontSize))")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    
                                    Slider(value: $fontSize, in: 10...24, step: 1)
                                        .frame(width: 100)
                                }
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Character Count")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Show character count in editor")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $showCharacterCount)
                                    .toggleStyle(.switch)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("About", systemImage: "info.circle")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("MarkTo")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Version 1.0.0")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "doc.richtext")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                                
                                Text("A lightweight macOS app for converting Markdown to Rich Text Format.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(nil)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                            
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Developer")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Attach.design")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "person.circle")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                                .padding(16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(.quaternary, lineWidth: 0.5)
                                )
                                
                                Button(action: {
                                    if let url = URL(string: "https://MarkTo.attach.design/privacy.html") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Privacy Policy")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("View our privacy policy")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(.quaternary, lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.primary)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Copyright")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("© 2025 Attach.design. All rights reserved.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "c.circle")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(.quaternary, lineWidth: 0.5)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 450, height: 400)
    }
}
