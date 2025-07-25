import Foundation
import AppKit

// MARK: - List Processor
/// Handles all list-related markdown processing including nested lists, task lists, and continuations
class ListProcessor {
    private let inlineProcessor: InlineProcessor
    
    init(inlineProcessor: InlineProcessor) {
        self.inlineProcessor = inlineProcessor
    }
    
    // MARK: - Public Methods
    
    /// Process unordered list item
    func createUnorderedListItem(_ text: String, level: Int, context: ParsingContext) -> NSAttributedString {
        let content = inlineProcessor.processInlineMarkdown(text, baseFont: context.baseFont, codeFont: context.codeFont)
        let result = NSMutableAttributedString(attributedString: content)
        
        // Create proper RTF list using NSTextList with level-appropriate markers
        let markerFormat: NSTextList.MarkerFormat
        switch level {
        case 0: markerFormat = .disc
        case 1: markerFormat = .circle
        case 2: markerFormat = .square
        default: markerFormat = .disc
        }
        
        let textList = NSTextList(markerFormat: markerFormat, options: 0)
        
        // Create paragraph style with NSTextList for proper RTF list formatting
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Configure indentation based on level
        let baseIndent: CGFloat = 20.0 * CGFloat(level)
        paragraphStyle.firstLineHeadIndent = baseIndent
        paragraphStyle.headIndent = baseIndent + 20.0
        paragraphStyle.tailIndent = 0
        paragraphStyle.paragraphSpacing = 2.0
        
        // Add the text list to create proper RTF list structure
        paragraphStyle.textLists = [textList]
        
        // Apply the paragraph style with list formatting
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    /// Process ordered list item
    func createOrderedListItem(_ text: String, number: String, level: Int, context: ParsingContext) -> NSAttributedString {
        let content = inlineProcessor.processInlineMarkdown(text, baseFont: context.baseFont, codeFont: context.codeFont)
        let result = NSMutableAttributedString(attributedString: content)
        
        // Create proper RTF numbered list using NSTextList
        let textList = NSTextList(markerFormat: .decimal, options: 0)
        
        // Create paragraph style with NSTextList for proper RTF list formatting
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Configure indentation based on level
        let baseIndent: CGFloat = 20.0 * CGFloat(level)
        paragraphStyle.firstLineHeadIndent = baseIndent
        paragraphStyle.headIndent = baseIndent + 25.0 // Slightly wider for numbers
        paragraphStyle.tailIndent = 0
        paragraphStyle.paragraphSpacing = 2.0
        
        // Add the text list to create proper RTF list structure
        paragraphStyle.textLists = [textList]
        
        // Apply the paragraph style with list formatting
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    /// Process task list item (checkbox)
    func createTaskListItem(_ text: String, isChecked: Bool, level: Int, context: ParsingContext) -> NSAttributedString {
        let checkbox = isChecked ? "☑ " : "☐ "
        
        let result = NSMutableAttributedString(string: checkbox)
        result.addAttributes([.font: context.baseFont], range: NSRange(location: 0, length: result.length))
        
        let content = inlineProcessor.processInlineMarkdown(text, baseFont: context.baseFont, codeFont: context.codeFont)
        let mutableContent = NSMutableAttributedString(attributedString: content)
        
        if isChecked {
            mutableContent.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: mutableContent.length))
            mutableContent.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSRange(location: 0, length: mutableContent.length))
        }
        result.append(mutableContent)
        
        // Apply proper paragraph style with hanging indent and level-based indentation
        let paragraphStyle = NSMutableParagraphStyle()
        let baseIndent: CGFloat = 20.0 * CGFloat(level)
        let hangingIndent: CGFloat = 20.0 // Space for checkbox
        
        paragraphStyle.firstLineHeadIndent = baseIndent
        paragraphStyle.headIndent = baseIndent + hangingIndent
        paragraphStyle.tailIndent = 0
        paragraphStyle.paragraphSpacing = 2.0
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    /// Create list continuation (content that follows a list item)
    func createListContinuation(_ text: String, level: Int, context: ParsingContext) -> NSAttributedString {
        let content = inlineProcessor.processInlineMarkdown(text.trimmingCharacters(in: .whitespaces), 
                                                           baseFont: context.baseFont, 
                                                           codeFont: context.codeFont)
        let result = NSMutableAttributedString(attributedString: content)
        
        // Apply paragraph style that continues the list indentation
        let paragraphStyle = NSMutableParagraphStyle()
        let baseIndent: CGFloat = 20.0
        let hangingIndent: CGFloat = 15.0
        
        paragraphStyle.firstLineHeadIndent = CGFloat(level) * baseIndent + hangingIndent
        paragraphStyle.headIndent = CGFloat(level) * baseIndent + hangingIndent
        paragraphStyle.tailIndent = 0
        paragraphStyle.paragraphSpacing = 2.0
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    // MARK: - List Detection and Analysis
    
    /// Calculate indentation level from line prefix
    func calculateIndentLevel(_ prefix: String) -> Int {
        // Count leading whitespace - support both spaces and tabs
        let spaces = prefix.filter { $0 == " " }.count
        let tabs = prefix.filter { $0 == "\t" }.count
        
        // More flexible indentation handling for real-world content
        if spaces > 0 {
            // Level 0: 0-1 spaces
            // Level 1: 2-5 spaces  
            // Level 2: 6+ spaces
            if spaces <= 1 {
                return 0
            } else if spaces <= 5 {
                return 1
            } else {
                return 2 + (spaces - 6) / 4  // Additional levels every 4 spaces beyond 6
            }
        }
        
        // Tab-based indentation: 1 tab = 1 level
        return tabs
    }
    
    /// Check if line is a continuation of current list
    func isListContinuation(_ line: String, listContext: ListContext) -> Bool {
        if !listContext.isInList { return false }
        
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Empty lines are allowed in lists (handled elsewhere)
        if trimmed.isEmpty { return false }
        
        // Lines that start with significant whitespace and aren't new list items are continuations
        if line.hasPrefix("  ") || line.hasPrefix("\t") {
            // Make sure it's not a new list item
            let isNewUnorderedList = trimmed.range(of: #"^([-*+])\s"#, options: .regularExpression) != nil
            let isNewOrderedList = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
            let isTaskList = trimmed.range(of: #"^([-*+])\s*\[([ xX])\]\s"#, options: .regularExpression) != nil
            
            if !isNewUnorderedList && !isNewOrderedList && !isTaskList {
                return true
            }
        }
        
        // Special case: lines that are clearly part of structured content
        // Even without leading whitespace, some patterns indicate continuation
        if trimmed.hasPrefix("**") && (trimmed.contains(":**") || trimmed.contains(":** ")) {
            // Pattern like "**Problem:** text" or "**Goal:** text"
            return true
        }
        
        // Another common pattern: lines that start with "- **" (sub-bullets with bold text)
        if trimmed.hasPrefix("- **") {
            return false // This is actually a new list item, not a continuation
        }
        
        // If we're in a list and this line has reasonable indentation but isn't a new list item
        // and the previous line was a list item, this is likely a continuation
        if listContext.lastWasListItem {
            let leadingSpaces = line.prefix(while: { $0 == " " }).count
            let leadingTabs = line.prefix(while: { $0 == "\t" }).count
            
            // If there's some indentation and it's not a clearly new item, treat as continuation
            if (leadingSpaces >= 2 || leadingTabs >= 1) && !isNewListItem(trimmed) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if trimmed line represents a new list item
    private func isNewListItem(_ trimmed: String) -> Bool {
        let isUnordered = trimmed.range(of: #"^([-*+])\s"#, options: .regularExpression) != nil
        let isOrdered = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
        let isTask = trimmed.range(of: #"^([-*+])\s*\[([ xX])\]\s"#, options: .regularExpression) != nil
        let isDefinition = trimmed.hasPrefix(": ")
        
        return isUnordered || isOrdered || isTask || isDefinition
    }
    
    /// Get appropriate list level from line content
    func getListLevel(_ line: String) -> Int {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Find the list marker and calculate indent level
        if let match = trimmed.range(of: #"^(\s*)([-*+]|\d+\.)\s+"#, options: .regularExpression) {
            let prefix = String(trimmed[..<match.upperBound])
            return calculateIndentLevel(prefix)
        }
        
        // For task lists
        if let match = trimmed.range(of: #"^(\s*)([-*+])\s*\[([ xX])\]\s+"#, options: .regularExpression) {
            let prefix = String(trimmed[..<match.upperBound])
            return calculateIndentLevel(prefix)
        }
        
        return 0
    }
}
