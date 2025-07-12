import SwiftUI
import AppKit

// MARK: - Formatting Customization View
struct FormattingCustomizationView: View {
    @StateObject private var viewModel = FormattingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Main Content
            HStack(spacing: 0) {
                // Sidebar
                sidebarContent
                
                Divider()
                
                // Detail Panel
                detailContent
            }
        }
        .frame(minWidth: 750, minHeight: 500)
        .alert("Reset Element", isPresented: $viewModel.showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.confirmResetElement()
            }
        } message: {
            Text("Reset \(viewModel.selectedElement.displayName) to default formatting?")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Rich Text Formatting")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Export Settings") {
                    exportSettings()
                }
                .buttonStyle(.bordered)
                
                Button("Reset All", role: .destructive) {
                    viewModel.resetAllFormatting()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - Sidebar Content
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Search and Filter
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                }
                
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(ElementCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            Divider()
            
            // Elements List
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(viewModel.filteredElements, id: \.self) { element in
                        ElementRowButton(
                            element: element,
                            formatting: viewModel.formattingPreferences.getFormatting(for: element),
                            isSelected: viewModel.selectedElement == element
                        ) {
                            viewModel.selectElement(element)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Reset Current Element
            VStack {
                Divider()
                
                Button("Reset Current Element") {
                    viewModel.resetCurrentElement()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.orange)
                .padding()
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Detail Content
    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Element Header
            elementHeader
            
            Divider()
            
            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Live Preview
                    previewCard
                    
                    // Quick Presets
                    presetsSection
                    
                    // Detailed Controls
                    controlsGrid
                    
                    Spacer(minLength: 20)
                }
                .padding(20)
            }
        }
        .frame(minWidth: 450)
    }
    
    // MARK: - Element Header
    private var elementHeader: some View {            HStack {
                Image(systemName: iconForElement(viewModel.selectedElement))
                    .font(.title)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedElement.displayName)
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Customize appearance and spacing")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Live Preview", systemImage: "eye")
                    .font(.headline)
                Spacer()
            }
            
            Text(viewModel.selectedElement.exampleText)
                .font(.system(
                    size: viewModel.currentFormatting.fontSize,
                    weight: Font.Weight(viewModel.currentFormatting.fontWeight.nsWeight)
                ))
                .lineSpacing((viewModel.currentFormatting.lineSpacing - 1.0) * viewModel.currentFormatting.fontSize)
                .kerning(viewModel.currentFormatting.characterSpacing)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Presets Section
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Presets", systemImage: "wand.and.rays")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(FormattingPreset.allCases, id: \.self) { preset in
                    Button(preset.displayName) {
                        viewModel.applyPreset(preset)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Controls Grid
    private var controlsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Font Size Control
            fontSizeControl
            
            // Font Weight Control
            fontWeightControl
            
            // Line Spacing Control
            lineSpacingControl
            
            // Character Spacing (for code elements)
            if viewModel.selectedElement == .code {
                characterSpacingControl
            }
        }
    }
    
    // MARK: - Font Size Control
    private var fontSizeControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Font Size", systemImage: "textformat.size")
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text("\(Int(viewModel.currentFormatting.fontSize))pt")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .quaternaryLabelColor))
                    )
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.currentFormatting.fontSize },
                    set: { viewModel.updateFontSize($0) }
                ),
                in: 8...72,
                step: 1
            )
            
            HStack {
                Text("8pt")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("72pt")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Font Weight Control
    private var fontWeightControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Font Weight", systemImage: "bold")
                .font(.subheadline.weight(.medium))
            
            Picker("Font Weight", selection: Binding(
                get: { viewModel.currentFormatting.fontWeight },
                set: { viewModel.updateFontWeight($0) }
            )) {
                ForEach(FontWeight.allCases) { weight in
                    Text(weight.displayName).tag(weight)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Line Spacing Control
    private var lineSpacingControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Line Spacing", systemImage: "line.3.horizontal.decrease")
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text(String(format: "%.1f", viewModel.currentFormatting.lineSpacing))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .quaternaryLabelColor))
                    )
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.currentFormatting.lineSpacing },
                    set: { viewModel.updateLineSpacing($0) }
                ),
                in: 0.8...3.0,
                step: 0.1
            )
            
            HStack {
                Text("0.8")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("3.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Character Spacing Control
    private var characterSpacingControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Character Spacing", systemImage: "character.cursor.ibeam")
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text(String(format: "%.1f", viewModel.currentFormatting.characterSpacing))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .quaternaryLabelColor))
                    )
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.currentFormatting.characterSpacing },
                    set: { viewModel.updateCharacterSpacing($0) }
                ),
                in: -2.0...5.0,
                step: 0.1
            )
            
            HStack {
                Text("-2.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("5.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Helper Methods
    private func iconForElement(_ element: MarkdownElement) -> String {
        switch element {
        case .body, .listItem: return "text.alignleft"
        case .header1, .header2, .header3, .header4, .header5, .header6: return "textformat.size"
        case .bold: return "bold"
        case .italic: return "italic"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .blockquote: return "quote.bubble"
        }
    }
    
    private func exportSettings() {
        let exportText = viewModel.exportFormatting()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(exportText, forType: .string)
    }
}

// MARK: - Element Row Button
private struct ElementRowButton: View {
    let element: MarkdownElement
    let formatting: TextFormatting
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconForElement(element))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(element.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text("\(Int(formatting.fontSize))pt • \(formatting.fontWeight.displayName)")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
    
    private func iconForElement(_ element: MarkdownElement) -> String {
        switch element {
        case .body, .listItem: return "text.alignleft"
        case .header1, .header2, .header3, .header4, .header5, .header6: return "textformat.size"
        case .bold: return "bold"
        case .italic: return "italic"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .blockquote: return "quote.bubble"
        }
    }
}

// MARK: - Formatting Presets
enum FormattingPreset: String, CaseIterable {
    case compact = "Compact"
    case standard = "Standard"
    case spacious = "Spacious"
    case large = "Large"
    
    var displayName: String { rawValue }
    
    func apply(to formatting: inout TextFormatting, for element: MarkdownElement) {
        switch self {
        case .compact:
            formatting.lineSpacing = 1.0
            formatting.fontSize = max(10, formatting.fontSize - 2)
        case .standard:
            formatting.lineSpacing = 1.2
            // Keep current font size
        case .spacious:
            formatting.lineSpacing = 1.6
            formatting.fontSize = min(48, formatting.fontSize + 2)
        case .large:
            formatting.lineSpacing = 1.8
            formatting.fontSize = min(72, formatting.fontSize + 4)
        }
    }
}

// MARK: - Font Weight Extension
extension Font.Weight {
    init(_ nsWeight: NSFont.Weight) {
        switch nsWeight {
        case .ultraLight: self = .ultraLight
        case .thin: self = .thin
        case .light: self = .light
        case .regular: self = .regular
        case .medium: self = .medium
        case .semibold: self = .semibold
        case .bold: self = .bold
        case .heavy: self = .heavy
        case .black: self = .black
        default: self = .regular
        }
    }
}

// MARK: - Preview
#Preview {
    FormattingCustomizationView()
        .frame(width: 800, height: 600)
}
