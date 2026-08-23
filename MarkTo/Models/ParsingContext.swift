import Foundation
import AppKit

// MARK: - Parsing Context
/// Manages state during markdown parsing to handle nested elements and context-aware processing
class ParsingContext {
    // Document-level state
    var isInCodeBlock: Bool = false
    var codeBlockLanguage: String?
    var currentLineIndex: Int = 0
    var totalLines: Int = 0
    
    // List processing state
    var listContext: ListContext = ListContext()
    
    // Font configuration
    let baseFont: NSFont
    let codeFont: NSFont
    let headingFonts: [NSFont] // H1-H6 fonts
    let formatting: FormattingSnapshot
    
    // Performance optimization - pre-compiled regex patterns
    static let headerPattern = try! NSRegularExpression(pattern: #"^#{1,6}\s+"#)
    static let unorderedListPattern = try! NSRegularExpression(pattern: #"^(\s*)([-*+])\s+"#)
    static let orderedListPattern = try! NSRegularExpression(pattern: #"^(\s*)(\d+)\.\s+"#)
    static let taskListPattern = try! NSRegularExpression(pattern: #"^(\s*)([-*+])\s*\[([ xX])\]\s+"#)
    static let horizontalRulePattern = try! NSRegularExpression(pattern: #"^(\s{0,3})([-*_])\s*(\2\s*){2,}$"#)
    static let codeBlockPattern = try! NSRegularExpression(pattern: #"^```"#)
    
    // Trimmed variants are available to callers that have already discarded indentation.
    static let unorderedListTrimmedPattern = try! NSRegularExpression(pattern: #"^([-*+])\\s"#)
    static let orderedListTrimmedPattern = try! NSRegularExpression(pattern: #"^\\d+\\.\\s"#)
    static let taskListTrimmedPattern = try! NSRegularExpression(pattern: #"^([-*+])\\s*\\[([ xX])\\]\\s"#)
    static let anyListTrimmedPattern = try! NSRegularExpression(pattern: #"^([-*+]|\\d+\\.)\\s+"#)

    init(
        baseFont: NSFont = NSFont.systemFont(ofSize: 14),
        codeFont: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
        formatting: FormattingSnapshot = .defaults
    ) {
        self.formatting = formatting
        self.baseFont = Self.font(for: .body, formatting: formatting, fallback: baseFont)
        self.codeFont = Self.font(for: .code, formatting: formatting, fallback: codeFont)
        self.headingFonts = [
            Self.font(for: .header1, formatting: formatting),
            Self.font(for: .header2, formatting: formatting),
            Self.font(for: .header3, formatting: formatting),
            Self.font(for: .header4, formatting: formatting),
            Self.font(for: .header5, formatting: formatting),
            Self.font(for: .header6, formatting: formatting)
        ]
    }

    func font(for element: MarkdownElement) -> NSFont {
        Self.font(for: element, formatting: formatting)
    }

    func paragraphStyle(for element: MarkdownElement) -> NSMutableParagraphStyle {
        let elementFormatting = formatting.formatting(for: element)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = max(0, elementFormatting.lineSpacing - 1.0) * elementFormatting.fontSize
        return style
    }

    private static func font(
        for element: MarkdownElement,
        formatting: FormattingSnapshot,
        fallback: NSFont? = nil
    ) -> NSFont {
        let elementFormatting = formatting.formatting(for: element)
        let base: NSFont

        if element == .code {
            base = NSFont.monospacedSystemFont(
                ofSize: elementFormatting.fontSize,
                weight: elementFormatting.fontWeight.nsWeight
            )
        } else {
            base = NSFont.systemFont(
                ofSize: elementFormatting.fontSize,
                weight: elementFormatting.fontWeight.nsWeight
            )
        }

        if element == .italic {
            return NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)
        }

        return base.pointSize > 0 ? base : (fallback ?? base)
    }
    
    func reset() {
        isInCodeBlock = false
        codeBlockLanguage = nil
        currentLineIndex = 0
        listContext.reset()
    }
    
    func setTotalLines(_ count: Int) {
        totalLines = count
    }
    
    func nextLine() {
        currentLineIndex += 1
    }
    
    func isLastLine() -> Bool {
        return currentLineIndex >= totalLines - 1
    }
}

// MARK: - List Context (Enhanced)
class ListContext {
    var isInList: Bool = false
    var currentLevel: Int = 0
    var lastListType: ListType = .unordered
    var lastWasListItem: Bool = false
    var listStack: [ListInfo] = [] // Track nested list information
    
    enum ListType {
        case unordered, ordered, task, definition
    }
    
    struct ListInfo {
        let type: ListType
        let level: Int
        let startNumber: Int? // For ordered lists
    }
    
    func updateWith(level: Int, type: ListType, startNumber: Int? = nil) {
        isInList = true
        currentLevel = level
        lastListType = type
        lastWasListItem = true
        
        // Manage list stack for proper nesting
        while !listStack.isEmpty && listStack.last!.level >= level {
            listStack.removeLast()
        }
        
        listStack.append(ListInfo(type: type, level: level, startNumber: startNumber))
    }
    
    func reset() {
        isInList = false
        currentLevel = 0
        lastWasListItem = false
        listStack.removeAll()
    }
    
    func setContinuation() {
        lastWasListItem = false
    }
    
    func getCurrentListInfo() -> ListInfo? {
        return listStack.last
    }
    
    func getNextNumber(for level: Int) -> Int {
        // Find the ordered list at this level and return next number
        for i in stride(from: listStack.count - 1, through: 0, by: -1) {
            let listInfo = listStack[i]
            if listInfo.level == level && listInfo.type == .ordered {
                // Count items at this level
                return (listInfo.startNumber ?? 1) + 1
            }
        }
        return 1
    }
}
