import Foundation
import AppKit

// MARK: - Block Processor
/// Handles block-level markdown elements: headers, blockquotes, code blocks, horizontal rules
class BlockProcessor {
    private let inlineProcessor: InlineProcessor
    
    init(inlineProcessor: InlineProcessor) {
        self.inlineProcessor = inlineProcessor
    }
    
    // MARK: - Header Processing
    
    /// Create heading with specified level and text
    func createHeading(_ text: String, level: Int, context: ParsingContext) -> NSAttributedString {
        guard level >= 1 && level <= 6 else {
            return inlineProcessor.processInlineMarkdown(text, baseFont: context.baseFont, codeFont: context.codeFont)
        }
        
        let headingFont = context.headingFonts[level - 1]
        let codeFont = NSFont.monospacedSystemFont(ofSize: headingFont.pointSize * 0.9, weight: .regular)
        
        // Process inline markdown within heading
        let inlineProcessed = inlineProcessor.processInlineMarkdown(text, baseFont: headingFont, codeFont: codeFont)
        
        // Create a mutable copy to modify attributes
        let result = NSMutableAttributedString(attributedString: inlineProcessed)
        
        // Apply heading formatting to the entire string
        result.enumerateAttributes(in: NSRange(location: 0, length: result.length), options: []) { attributes, range, _ in
            var newAttributes = attributes
            
            // Preserve bold/italic formatting but ensure heading font size
            if let font = attributes[.font] as? NSFont {
                if font.fontDescriptor.symbolicTraits.contains(.bold) {
                    newAttributes[.font] = NSFont.boldSystemFont(ofSize: headingFont.pointSize)
                } else if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    newAttributes[.font] = NSFont.systemFont(ofSize: headingFont.pointSize).withTraits(.italic)
                } else {
                    newAttributes[.font] = headingFont
                }
            } else {
                newAttributes[.font] = headingFont
            }
            
            newAttributes[.foregroundColor] = NSColor.textColor
            result.setAttributes(newAttributes, range: range)
        }
        
        return result
    }
    
    // MARK: - Blockquote Processing
    
    /// Create blockquote with visual indicator
    func createBlockquote(_ text: String, context: ParsingContext) -> NSAttributedString {
        let result = NSMutableAttributedString(string: "▌ ")
        result.addAttributes([
            .foregroundColor: NSColor.quaternaryLabelColor,
            .font: context.baseFont
        ], range: NSRange(location: 0, length: 2))
        
        let content = inlineProcessor.processInlineMarkdown(text, baseFont: context.baseFont, codeFont: context.codeFont)
        result.append(content)
        
        // Add left margin/padding effect
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 20
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    // MARK: - Code Block Processing
    
    /// Create code block with optional language specification
    func createCodeBlock(_ lines: [String], language: String?, context: ParsingContext) -> NSAttributedString {
        let codeText = lines.joined(separator: "\n")
        
        let result = NSMutableAttributedString(string: codeText, attributes: [
            .font: context.codeFont,
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ])
        
        // Apply code block paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 10
        paragraphStyle.headIndent = 10
        paragraphStyle.tailIndent = -10
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    /// Create single line code block (indented with 4+ spaces)
    func createIndentedCodeBlock(_ line: String, context: ParsingContext) -> NSAttributedString {
        // Remove the 4-space indentation
        let codeText = String(line.dropFirst(4))
        
        return NSAttributedString(string: codeText, attributes: [
            .font: context.codeFont,
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ])
    }
    
    // MARK: - Horizontal Rule Processing
    
    /// Create horizontal rule/divider
    func createHorizontalRule() -> NSAttributedString {
        let rule = String(repeating: "─", count: 40)
        
        let result = NSMutableAttributedString(string: rule)
        result.addAttributes([
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.separatorColor
        ], range: NSRange(location: 0, length: result.length))
        
        // Center the rule
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.paragraphSpacingBefore = 10
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    // MARK: - Definition Lists
    
    /// Create definition list item
    func createDefinition(_ text: String, context: ParsingContext) -> NSAttributedString {
        let result = NSMutableAttributedString(string: "    ")
        result.addAttributes([.font: context.baseFont], range: NSRange(location: 0, length: 4))
        
        let content = inlineProcessor.processInlineMarkdown(text, baseFont: context.baseFont, codeFont: context.codeFont)
        result.append(content)
        
        // Apply definition-specific styling
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 20
        paragraphStyle.headIndent = 20
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    // MARK: - Detection Methods
    
    /// Check if line is a horizontal rule
    func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Must be at least 3 characters
        guard trimmed.count >= 3 else { return false }
        
        // Check for --- or *** or ___
        let hrPatterns = ["---", "***", "___"]
        for pattern in hrPatterns {
            if trimmed.hasPrefix(pattern) {
                // Ensure the rest are the same character or spaces
                let char = pattern.first!
                let valid = trimmed.allSatisfy { $0 == char || $0 == " " }
                if valid && trimmed.filter({ $0 == char }).count >= 3 {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Detect header level from line
    func getHeaderLevel(_ line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // ATX headers: # ## ### etc.
        if trimmed.hasPrefix("#") {
            let hashCount = trimmed.prefix(while: { $0 == "#" }).count
            if hashCount <= 6 && (trimmed.count > hashCount && trimmed[trimmed.index(trimmed.startIndex, offsetBy: hashCount)] == " ") {
                return hashCount
            }
        }
        
        return nil
    }
    
    /// Extract header text (removing # markers)
    func getHeaderText(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if let headerMatch = trimmed.range(of: #"^#{1,6}\s+"#, options: .regularExpression) {
            let text = String(trimmed[headerMatch.upperBound...])
            // Remove trailing # if present
            return text.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        }
        
        return trimmed
    }
}
