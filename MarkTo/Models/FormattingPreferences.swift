import Foundation
import SwiftUI

// MARK: - Markdown Elements
enum MarkdownElement: String, CaseIterable, Identifiable {
    case body = "body"
    case header1 = "header1"
    case header2 = "header2"
    case header3 = "header3"
    case header4 = "header4"
    case header5 = "header5"
    case header6 = "header6"
    case bold = "bold"
    case italic = "italic"
    case code = "code"
    case blockquote = "blockquote"
    case listItem = "listItem"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .body: return "Body Text"
        case .header1: return "Header 1"
        case .header2: return "Header 2"
        case .header3: return "Header 3"
        case .header4: return "Header 4"
        case .header5: return "Header 5"
        case .header6: return "Header 6"
        case .bold: return "Bold Text"
        case .italic: return "Italic Text"
        case .code: return "Code"
        case .blockquote: return "Blockquote"
        case .listItem: return "List Item"
        }
    }
    
    var exampleText: String {
        switch self {
        case .body: return "This is body text with normal formatting."
        case .header1: return "This is a Header 1"
        case .header2: return "This is a Header 2"
        case .header3: return "This is a Header 3"
        case .header4: return "This is a Header 4"
        case .header5: return "This is a Header 5"
        case .header6: return "This is a Header 6"
        case .bold: return "This is bold text"
        case .italic: return "This is italic text"
        case .code: return "console.log('code')"
        case .blockquote: return "This is a blockquote"
        case .listItem: return "• This is a list item"
        }
    }
    
    var category: ElementCategory {
        switch self {
        case .body, .listItem:
            return .text
        case .header1, .header2, .header3, .header4, .header5, .header6:
            return .headers
        case .bold, .italic, .code:
            return .inline
        case .blockquote:
            return .blocks
        }
    }
}

// MARK: - Element Categories
enum ElementCategory: String, CaseIterable {
    case headers = "Headers"
    case text = "Text"
    case inline = "Inline Formatting"
    case blocks = "Block Elements"
}

// MARK: - Font Weight
enum FontWeight: String, CaseIterable, Identifiable, Codable {
    case ultraLight = "ultraLight"
    case thin = "thin"
    case light = "light"
    case regular = "regular"
    case medium = "medium"
    case semibold = "semibold"
    case bold = "bold"
    case heavy = "heavy"
    case black = "black"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ultraLight: return "Ultra Light"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        case .heavy: return "Heavy"
        case .black: return "Black"
        }
    }
    
    var nsWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

// MARK: - Text Formatting
struct TextFormatting: Codable, Equatable {
    var fontSize: Double
    var fontWeight: FontWeight
    var lineSpacing: Double
    var characterSpacing: Double
    
    init(fontSize: Double = 12.0, 
         fontWeight: FontWeight = .regular, 
         lineSpacing: Double = 1.2, 
         characterSpacing: Double = 0.0) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.lineSpacing = lineSpacing
        self.characterSpacing = characterSpacing
    }
    
    // Default formatting for each element type
    static func defaultFormatting(for element: MarkdownElement) -> TextFormatting {
        switch element {
        case .body:
            return TextFormatting(fontSize: 12, fontWeight: .regular, lineSpacing: 1.4)
        case .header1:
            return TextFormatting(fontSize: 24, fontWeight: .bold, lineSpacing: 1.2)
        case .header2:
            return TextFormatting(fontSize: 20, fontWeight: .bold, lineSpacing: 1.2)
        case .header3:
            return TextFormatting(fontSize: 18, fontWeight: .semibold, lineSpacing: 1.2)
        case .header4:
            return TextFormatting(fontSize: 16, fontWeight: .semibold, lineSpacing: 1.2)
        case .header5:
            return TextFormatting(fontSize: 14, fontWeight: .medium, lineSpacing: 1.2)
        case .header6:
            return TextFormatting(fontSize: 12, fontWeight: .medium, lineSpacing: 1.2)
        case .bold:
            return TextFormatting(fontSize: 12, fontWeight: .bold, lineSpacing: 1.4)
        case .italic:
            return TextFormatting(fontSize: 12, fontWeight: .regular, lineSpacing: 1.4)
        case .code:
            return TextFormatting(fontSize: 11, fontWeight: .regular, lineSpacing: 1.3, characterSpacing: 0.5)
        case .blockquote:
            return TextFormatting(fontSize: 12, fontWeight: .regular, lineSpacing: 1.5)
        case .listItem:
            return TextFormatting(fontSize: 12, fontWeight: .regular, lineSpacing: 1.4)
        }
    }
}

// MARK: - Formatting Preferences
@MainActor
class FormattingPreferences: ObservableObject {
    @Published var formatSettings: [MarkdownElement: TextFormatting] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let formattingKey = "customFormatting"
    
    init() {
        loadFormatting()
    }
    
    // MARK: - Public Methods
    func getFormatting(for element: MarkdownElement) -> TextFormatting {
        return formatSettings[element] ?? TextFormatting.defaultFormatting(for: element)
    }
    
    func setFormatting(_ formatting: TextFormatting, for element: MarkdownElement) {
        formatSettings[element] = formatting
        saveFormatting()
    }
    
    func resetToDefaults() {
        formatSettings.removeAll()
        for element in MarkdownElement.allCases {
            formatSettings[element] = TextFormatting.defaultFormatting(for: element)
        }
        saveFormatting()
    }
    
    func resetElement(_ element: MarkdownElement) {
        formatSettings[element] = TextFormatting.defaultFormatting(for: element)
        saveFormatting()
    }
    
    // MARK: - Private Methods
    private func loadFormatting() {
        // Load saved formatting or initialize with defaults
        if let data = userDefaults.data(forKey: formattingKey),
           let decoded = try? JSONDecoder().decode([String: TextFormatting].self, from: data) {
            
            // Convert string keys back to enum keys
            for (key, value) in decoded {
                if let element = MarkdownElement(rawValue: key) {
                    formatSettings[element] = value
                }
            }
        }
        
        // Ensure all elements have formatting (fill in any missing with defaults)
        for element in MarkdownElement.allCases {
            if formatSettings[element] == nil {
                formatSettings[element] = TextFormatting.defaultFormatting(for: element)
            }
        }
    }
    
    private func saveFormatting() {
        // Convert enum keys to string keys for JSON encoding
        let stringKeyedSettings = formatSettings.reduce(into: [String: TextFormatting]()) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        
        if let encoded = try? JSONEncoder().encode(stringKeyedSettings) {
            userDefaults.set(encoded, forKey: formattingKey)
        }
    }
}
