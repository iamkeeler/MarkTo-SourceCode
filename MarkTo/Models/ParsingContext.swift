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
    
    // Performance optimization - pre-compiled regex patterns
    static let headerPattern = try! NSRegularExpression(pattern: #"^#{1,6}\s+"#)
    static let unorderedListPattern = try! NSRegularExpression(pattern: #"^(\s*)([-*+])\s+"#)
    static let orderedListPattern = try! NSRegularExpression(pattern: #"^(\s*)(\d+)\.\s+"#)
    static let taskListPattern = try! NSRegularExpression(pattern: #"^(\s*)([-*+])\s*\[([ xX])\]\s+"#)
    static let horizontalRulePattern = try! NSRegularExpression(pattern: #"^(\s{0,3})([-*_])\s*(\2\s*){2,}$"#)
    static let codeBlockPattern = try! NSRegularExpression(pattern: #"^```"#)
    
    init(baseFont: NSFont = NSFont.systemFont(ofSize: 14), 
         codeFont: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)) {
        self.baseFont = baseFont
        self.codeFont = codeFont
        
        // Pre-calculate heading fonts for performance
        self.headingFonts = [
            NSFont.boldSystemFont(ofSize: 24), // H1
            NSFont.boldSystemFont(ofSize: 20), // H2
            NSFont.boldSystemFont(ofSize: 18), // H3
            NSFont.boldSystemFont(ofSize: 16), // H4
            NSFont.boldSystemFont(ofSize: 14), // H5
            NSFont.boldSystemFont(ofSize: 13)  // H6
        ]
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
