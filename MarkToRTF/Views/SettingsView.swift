import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    @AppStorage("autoLoadClipboard") private var autoLoadClipboard: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Customize your MarkToRTF experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background(.regularMaterial, in: Rectangle())
            
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
                            
                            VStack(spacing: 8) {
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
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Auto-load Clipboard")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Load clipboard content on app launch")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $autoLoadClipboard)
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
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
        .background(.ultraThinMaterial)
        .frame(width: 450, height: 400)
    }
}
