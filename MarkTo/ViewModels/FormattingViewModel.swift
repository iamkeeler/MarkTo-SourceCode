import Foundation
import SwiftUI
import Combine

// MARK: - Formatting View Model
@MainActor
class FormattingViewModel: ObservableObject {
    @Published var formattingPreferences: FormattingPreferences
    @Published var selectedElement: MarkdownElement = .body
    @Published var selectedCategory: ElementCategory = .text
    @Published var searchText: String = ""
    @Published var showResetAlert: Bool = false
    @Published var elementToReset: MarkdownElement?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(formattingPreferences: FormattingPreferences? = nil) {
        self.formattingPreferences = formattingPreferences ?? FormattingPreferences()
        setupBindings()
    }
    
    // MARK: - Computed Properties
    var filteredElements: [MarkdownElement] {
        let elementsInCategory = MarkdownElement.allCases.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return elementsInCategory
        } else {
            return elementsInCategory.filter { element in
                element.displayName.localizedCaseInsensitiveContains(searchText) ||
                element.exampleText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var currentFormatting: TextFormatting {
        get {
            formattingPreferences.getFormatting(for: selectedElement)
        }
        set {
            formattingPreferences.setFormatting(newValue, for: selectedElement)
        }
    }
    
    // MARK: - Actions
    func selectElement(_ element: MarkdownElement) {
        selectedElement = element
        selectedCategory = element.category
    }
    
    func updateFontSize(_ size: Double) {
        var formatting = currentFormatting
        formatting.fontSize = size
        currentFormatting = formatting
    }
    
    func updateFontWeight(_ weight: FontWeight) {
        var formatting = currentFormatting
        formatting.fontWeight = weight
        currentFormatting = formatting
    }
    
    func updateLineSpacing(_ spacing: Double) {
        var formatting = currentFormatting
        formatting.lineSpacing = spacing
        currentFormatting = formatting
    }
    
    func updateCharacterSpacing(_ spacing: Double) {
        var formatting = currentFormatting
        formatting.characterSpacing = spacing
        currentFormatting = formatting
    }
    
    func applyPreset(_ preset: FormattingPreset) {
        var formatting = currentFormatting
        preset.apply(to: &formatting, for: selectedElement)
        currentFormatting = formatting
    }
    
    func resetCurrentElement() {
        elementToReset = selectedElement
        showResetAlert = true
    }
    
    func confirmResetElement() {
        guard let element = elementToReset else { return }
        formattingPreferences.resetElement(element)
        elementToReset = nil
    }
    
    func resetAllFormatting() {
        formattingPreferences.resetToDefaults()
    }
    
    func exportFormatting() -> String {
        // Create a formatted string showing all current settings
        var export = "MarkTo Formatting Settings\n"
        export += "==========================\n\n"
        
        for category in ElementCategory.allCases {
            export += "\(category.rawValue):\n"
            let elementsInCategory = MarkdownElement.allCases.filter { $0.category == category }
            
            for element in elementsInCategory {
                let formatting = formattingPreferences.getFormatting(for: element)
                export += "  \(element.displayName):\n"
                export += "    Font Size: \(Int(formatting.fontSize))pt\n"
                export += "    Font Weight: \(formatting.fontWeight.displayName)\n"
                export += "    Line Spacing: \(String(format: "%.1f", formatting.lineSpacing))\n"
                if formatting.characterSpacing != 0 {
                    export += "    Character Spacing: \(String(format: "%.1f", formatting.characterSpacing))pt\n"
                }
                export += "\n"
            }
        }
        
        return export
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Any additional reactive bindings can be set up here
        formattingPreferences.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Preview Helper
    func getPreviewAttributedString(for element: MarkdownElement) -> NSAttributedString {
        let formatting = formattingPreferences.getFormatting(for: element)
        let font = NSFont.systemFont(
            ofSize: formatting.fontSize,
            weight: formatting.fontWeight.nsWeight
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = (formatting.lineSpacing - 1.0) * formatting.fontSize
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .kern: formatting.characterSpacing
        ]
        
        return NSAttributedString(string: element.exampleText, attributes: attributes)
    }
}
