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
            // Header
            HStack {
                Text("MarkToRTF")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if showCloseButton {
                    Button(action: {
                        if let window = NSApplication.shared.keyWindow {
                            window.performClose(nil)
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .opacity(isHovering ? 1 : 0)
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovering = hovering
                        }
                    }
                    .accessibilityLabel("Close window")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Main content
            VStack(spacing: 16) {
                // Markdown input area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Markdown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if showCharacterCount {
                            Text("\(viewModel.markdownText.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextEditor(text: $viewModel.markdownText)
                        .font(.system(size: fontSize, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .accessibilityLabel("Markdown input text editor")
                }
                
                // Convert button
                Button(action: {
                    viewModel.convertToRTF()
                }) {
                    HStack {
                        if viewModel.isConverting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14, weight: .medium))
                        }
                        
                        Text(viewModel.isConverting ? "Converting..." : "Convert to RTF & Copy")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.markdownText.isEmpty ? Color.gray : Color.blue)
                    )
                }
                .disabled(viewModel.markdownText.isEmpty || viewModel.isConverting)
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(viewModel.isConverting ? "Converting markdown to RTF" : "Convert markdown to RTF and copy to clipboard")
                .keyboardShortcut("r", modifiers: .command)
                
                // Status message
                if !viewModel.statusMessage.isEmpty {
                    HStack {
                        Image(systemName: viewModel.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(viewModel.isSuccess ? .green : .red)
                            .font(.system(size: 14))
                        
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundColor(viewModel.isSuccess ? .green : .red)
                        
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityLabel("Status: \(viewModel.statusMessage)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(NSColor.windowBackgroundColor))
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
