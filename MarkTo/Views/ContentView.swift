import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var isHovering = false
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    @AppStorage("autoLoadClipboard") private var autoLoadClipboard: Bool = true
    
    let showCloseButton: Bool
    
    init(showCloseButton: Bool = true) {
        self.showCloseButton = showCloseButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with glass effect
            HStack {
                Text("MarkTo")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if showCloseButton {
                    Button(action: {
                        if let window = NSApplication.shared.keyWindow {
                            window.performClose(nil)
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)
                    .background(.quaternary, in: Circle())
                    .scaleEffect(isHovering ? 1.1 : 1.0)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isHovering = hovering
                        }
                    }
                    .accessibilityLabel("Close window")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(.regularMaterial, in: Rectangle())
            
            // Main content with glass background
            VStack(spacing: 20) {
                // Markdown input area
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Markdown", systemImage: "text.alignleft")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if showCharacterCount {
                            Text("\(viewModel.markdownText.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    
                    TextEditor(text: $viewModel.markdownText)
                        .font(.system(size: fontSize, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .frame(minHeight: 160)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.quaternary, lineWidth: 0.5)
                        )
                        .accessibilityLabel("Markdown input text editor")
                }
                
                // Convert button with glass effect
                Button(action: {
                    viewModel.convertToRTF()
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isConverting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text(viewModel.isConverting ? "Converting..." : "Convert to RTF")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Group {
                            if viewModel.markdownText.isEmpty {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.quaternary)
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.blue.gradient)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .disabled(viewModel.markdownText.isEmpty || viewModel.isConverting)
                .buttonStyle(.plain)
                .scaleEffect(viewModel.isConverting ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isConverting)
                .accessibilityLabel(viewModel.isConverting ? "Converting markdown to RTF" : "Convert markdown to RTF and copy to clipboard")
                .keyboardShortcut("r", modifiers: .command)
                
                // Status message with glass background
                if !viewModel.statusMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(viewModel.isSuccess ? .green : .orange)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(viewModel.statusMessage)
                            .font(.subheadline)
                            .foregroundStyle(viewModel.isSuccess ? .green : .orange)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(viewModel.isSuccess ? .green.opacity(0.3) : .orange.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                    .accessibilityLabel("Status: \(viewModel.statusMessage)")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            if autoLoadClipboard {
                viewModel.loadClipboardContent()
            }
        }
    }
}

#Preview {
    ContentView(showCloseButton: true)
}
