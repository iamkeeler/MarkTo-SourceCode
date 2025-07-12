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
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(ElementCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: iconForCategory(category))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundStyle(.blue)
                Text("Live Preview")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                
                // Current values display
                HStack(spacing: 12) {
                    Text("\(Int(viewModel.currentFormatting.fontSize))pt")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(viewModel.currentFormatting.fontWeight.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("×\(String(format: "%.1f", viewModel.currentFormatting.lineSpacing))")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                .foregroundStyle(.secondary)
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Presets Section
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.rays")
                    .foregroundStyle(.purple)
                Text("Quick Presets")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(FormattingPreset.allCases, id: \.self) { preset in
                    Button(action: { viewModel.applyPreset(preset) }) {
                        VStack(spacing: 4) {
                            Image(systemName: preset.iconName)
                                .font(.title2)
                                .foregroundStyle(.purple)
                            
                            Text(preset.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Controls Grid
    private var controlsGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Typography Section
            typographySection
            
            // Spacing Section
            spacingSection
            
            // Character Spacing (for code elements)
            if viewModel.selectedElement == .code {
                advancedSection
            }
        }
    }
    
    // MARK: - Typography Section
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "textformat.abc")
                    .foregroundStyle(.blue)
                Text("Typography")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Font Size Control
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Font Size")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        TextField("Size", 
                                value: Binding(
                                    get: { Int(viewModel.currentFormatting.fontSize) },
                                    set: { viewModel.updateFontSize(Double($0)) }
                                ),
                                format: .number
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        
                        Text("pt")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Stepper("", 
                               value: Binding(
                                   get: { viewModel.currentFormatting.fontSize },
                                   set: { viewModel.updateFontSize($0) }
                               ),
                               in: 8...72,
                               step: 1
                        )
                        .labelsHidden()
                    }
                }
                
                Spacer()
                
                // Font Weight Control
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Font Weight", selection: Binding(
                        get: { viewModel.currentFormatting.fontWeight },
                        set: { viewModel.updateFontWeight($0) }
                    )) {
                        ForEach(FontWeight.allCases) { weight in
                            Text(weight.displayName).tag(weight)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Spacing Section
    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(.green)
                Text("Spacing")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Line Spacing Control
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Line Spacing")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        TextField("Spacing", 
                                value: Binding(
                                    get: { viewModel.currentFormatting.lineSpacing },
                                    set: { viewModel.updateLineSpacing($0) }
                                ),
                                format: .number.precision(.fractionLength(1))
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                        
                        Stepper("", 
                               value: Binding(
                                   get: { viewModel.currentFormatting.lineSpacing },
                                   set: { viewModel.updateLineSpacing($0) }
                               ),
                               in: 0.8...3.0,
                               step: 0.1
                        )
                        .labelsHidden()
                    }
                }
                
                Spacer()
                
                // Quick spacing buttons
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Set")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Button("Tight") {
                            viewModel.updateLineSpacing(1.0)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Normal") {
                            viewModel.updateLineSpacing(1.2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Loose") {
                            viewModel.updateLineSpacing(1.6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Advanced Section
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.orange)
                Text("Advanced")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Character Spacing Control
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Character Spacing")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        TextField("Spacing", 
                                value: Binding(
                                    get: { viewModel.currentFormatting.characterSpacing },
                                    set: { viewModel.updateCharacterSpacing($0) }
                                ),
                                format: .number.precision(.fractionLength(1))
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                        
                        Text("pts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Stepper("", 
                               value: Binding(
                                   get: { viewModel.currentFormatting.characterSpacing },
                                   set: { viewModel.updateCharacterSpacing($0) }
                               ),
                               in: -2.0...5.0,
                               step: 0.1
                        )
                        .labelsHidden()
                    }
                }
                
                Spacer()
                
                // Quick character spacing buttons
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Set")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Button("Tight") {
                            viewModel.updateCharacterSpacing(-0.5)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Normal") {
                            viewModel.updateCharacterSpacing(0.0)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Wide") {
                            viewModel.updateCharacterSpacing(1.0)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
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
    
    private func iconForCategory(_ category: ElementCategory) -> String {
        switch category {
        case .headers: return "textformat.size"
        case .text: return "text.alignleft"
        case .inline: return "textformat"
        case .blocks: return "square.stack"
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
    
    var iconName: String {
        switch self {
        case .compact: return "arrow.down.square"
        case .standard: return "square"
        case .spacious: return "arrow.up.square"
        case .large: return "plus.square"
        }
    }
    
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
