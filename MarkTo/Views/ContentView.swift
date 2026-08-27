import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    var isMenuBar: Bool = false
    var onOpenSettings: (() -> Void)? = nil
    var popoverArrowOffset: CGFloat = 0

    @State private var isHoveringSettings = false
    @State private var isFileDropTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            editorSection
            convertButton

            if !viewModel.statusMessage.isEmpty {
                statusBanner
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, isMenuBar ? 32 : 24)
        .padding(.bottom, viewModel.statusMessage.isEmpty ? 24 : 32)
        .navigationTitle("MarkTo")
        .background { containerBackground }
        .mask { containerMask }
        .onDrop(of: [UTType.fileURL], isTargeted: $isFileDropTargeted, perform: handleFileDrop(providers:))
        .overlay { fileDropOverlay }
        .onReceive(NotificationCenter.default.publisher(for: .markdownFileConversionCompleted)) { notification in
            guard let result = notification.userInfo?["result"] as? Result<MarkdownFileConversionResult, MarkdownFileConversionError> else {
                return
            }
            viewModel.handleExternalFileConversion(result)
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
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
                        .accessibilityLabel("\(viewModel.markdownText.count) characters")
                }

                settingsButton
            }

            TextEditor(text: $viewModel.markdownText)
                .font(.system(size: fontSize, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 160)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                }
                .accessibilityLabel("Markdown input text editor")
                // TextEditor normally inserts a dropped file URL as text. Handle the
                // drop here as well as on the enclosing surface so it becomes an export.
                .onDrop(of: [UTType.fileURL], isTargeted: $isFileDropTargeted, perform: handleFileDrop(providers:))

            Text("Drop a .md file here to create a sibling RTF document")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }

    private var settingsButton: some View {
        Button {
            if let onOpenSettings {
                onOpenSettings()
            } else {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHoveringSettings ? Color.primary.opacity(0.08) : .clear)
                }
        }
        .buttonStyle(.plain)
        .onHover { isHoveringSettings = $0 }
        .help("Settings (⌘,)")
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("openSettingsButton")
    }

    private var convertButton: some View {
        Button {
            viewModel.convertToRTF()
        } label: {
            HStack(spacing: 8) {
                if viewModel.isConverting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(.circular)
                        .tint(.white)
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
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(convertButtonColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            }
        }
        .disabled(viewModel.markdownText.isEmpty || viewModel.isConverting)
        .buttonStyle(.plain)
        .scaleEffect(viewModel.isConverting ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isConverting)
        .accessibilityLabel(
            viewModel.isConverting
                ? "Converting markdown to RTF"
                : "Convert markdown to RTF and copy to clipboard"
        )
        .keyboardShortcut("r", modifiers: .command)
    }

    private var convertButtonColor: Color {
        viewModel.markdownText.isEmpty ? Color.secondary.opacity(0.35) : .accentColor
    }

    private var statusBanner: some View {
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
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    viewModel.isSuccess ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
                    lineWidth: 1
                )
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .accessibilityLabel("Status: \(viewModel.statusMessage)")
    }

    @ViewBuilder
    private var fileDropOverlay: some View {
        if isFileDropTargeted {
            RoundedRectangle(cornerRadius: isMenuBar ? 16 : 20)
                .fill(.tint.opacity(0.14))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.system(size: 28, weight: .medium))
                        Text("Convert Markdown File")
                            .font(.headline)
                        Text("Creates an RTF beside the source file")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.tint)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: isMenuBar ? 16 : 20)
                        .strokeBorder(.tint, style: StrokeStyle(lineWidth: 2, dash: [6]))
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let itemURL = item as? URL {
                url = itemURL
            } else if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = nil
            }

            guard let url else { return }
            Task { @MainActor in
                viewModel.convertMarkdownFile(at: url)
            }
        }
        return true
    }

    @ViewBuilder
    private var containerBackground: some View {
        if isMenuBar {
            PopoverShape(arrowOffset: popoverArrowOffset)
                .fill(.ultraThinMaterial)
                .overlay {
                    PopoverShape(arrowOffset: popoverArrowOffset)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var containerMask: some View {
        if isMenuBar {
            PopoverShape(arrowOffset: popoverArrowOffset)
        } else {
            RoundedRectangle(cornerRadius: 20)
        }
    }
}

// MARK: - Popover Anchor Shape
struct PopoverShape: Shape {
    var arrowWidth: CGFloat = 16
    var arrowHeight: CGFloat = 8
    var cornerRadius: CGFloat = 16
    var arrowOffset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let bodyTop = rect.minY + arrowHeight
        let arrowCenter = rect.midX + arrowOffset
        let arrowLeft = arrowCenter - arrowWidth / 2
        let arrowRight = arrowCenter + arrowWidth / 2

        // Top edge after top-left corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: bodyTop))

        // Line to left base of arrow
        path.addLine(to: CGPoint(x: arrowLeft, y: bodyTop))

        // Arrow peak (uptick pointing to menu bar icon)
        path.addLine(to: CGPoint(x: arrowCenter, y: rect.minY))

        // Line to right base of arrow
        path.addLine(to: CGPoint(x: arrowRight, y: bodyTop))

        // Line to top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: bodyTop))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: bodyTop + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: bodyTop + cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: bodyTop + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}
