import Foundation
import AppKit

// MARK: - Inline Processor
/// Handles inline markdown formatting: bold, italic, code, links, etc.
class InlineProcessor {
    
    // Pre-compiled patterns for performance - using safe, simple patterns
    private static let escapePattern = try! NSRegularExpression(pattern: #"\\(.)"#)
    private static let boldPattern = try! NSRegularExpression(pattern: #"\*\*(.*?)\*\*"#)
    private static let boldUnderscorePattern = try! NSRegularExpression(pattern: #"__(.*?)__"#)
    private static let italicPattern = try! NSRegularExpression(pattern: #"\*(.*?)\*"#)
    private static let italicUnderscorePattern = try! NSRegularExpression(pattern: #"_(.*?)_"#)
    private static let codePattern = try! NSRegularExpression(pattern: #"`([^`]+)`"#)
    private static let strikethroughPattern = try! NSRegularExpression(pattern: #"~~(.*?)~~"#)
    private static let linkPattern = try! NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#)
    private static let autoLinkPattern = try! NSRegularExpression(pattern: #"<(https?://[^>]+|[^@\s]+@[^@\s]+\.[^@\s]+)>"#)
    private static let bareURLPattern = try! NSRegularExpression(pattern: #"\b(https?://[^\s<>"`{}\\]{1,100})\b"#)
    private static let emojiPattern = try! NSRegularExpression(pattern: #":([a-zA-Z0-9_+-]{1,32}):"#)
    private static let imagePattern = try! NSRegularExpression(pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#)
    
    /// Process inline markdown formatting in text
    /// - Parameters:
    ///   - text: Raw text with markdown formatting
    ///   - baseFont: Font to use for regular text
    ///   - codeFont: Font to use for code spans
    /// - Returns: NSAttributedString with applied formatting
    func processInlineMarkdown(_ text: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        // Safety check: limit input size to prevent memory issues
        let maxLength = 50000 // 50KB limit
        let processText = text.count > maxLength ? String(text.prefix(maxLength)) : text
        
        // First, preprocess escape sequences to protect them from formatting
        let escapedText = preprocessEscapes(processText)
        let result = NSMutableAttributedString(string: escapedText, attributes: [.font: baseFont])
        
        // Process in specific order to handle overlapping patterns correctly
        processStrikethrough(in: result, baseFont: baseFont)
        processBold(in: result, baseFont: baseFont)
        processItalic(in: result, baseFont: baseFont)
        processCode(in: result, codeFont: codeFont)
        processImages(in: result, baseFont: baseFont)
        processLinks(in: result, baseFont: baseFont)
        processAutoLinks(in: result, baseFont: baseFont)
        processBareURLs(in: result, baseFont: baseFont)
        processEmojis(in: result, baseFont: baseFont)
        
        return result
    }
    
    // MARK: - Private Processing Methods
    
    private func processStrikethrough(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.strikethroughPattern.matches(in: string, range: range)
        
        // Process in reverse order to maintain indices
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            if let contentSwiftRange = Range(contentRange, in: string) {
                let content = String(string[contentSwiftRange])
                
                // Replace with styled content
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: content,
                    attributes: [
                        .font: baseFont,
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue
                    ]
                ))
            }
        }
    }
    
    private func processBold(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        // Process ** bold ** first
        processBoldPattern(Self.boldPattern, in: attributedString, baseFont: baseFont)
        
        // Then process __ bold __
        processBoldPattern(Self.boldUnderscorePattern, in: attributedString, baseFont: baseFont)
    }
    
    private func processBoldPattern(_ pattern: NSRegularExpression, in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let range = NSRange(location: 0, length: string.count)
        
        let matches = pattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            if let contentSwiftRange = Range(contentRange, in: string) {
                let content = String(string[contentSwiftRange])
                let boldFont = NSFont.boldSystemFont(ofSize: baseFont.pointSize)
                
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: content,
                    attributes: [.font: boldFont]
                ))
            }
        }
    }
    
    private func processItalic(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        processItalicPattern(Self.italicPattern, in: attributedString, baseFont: baseFont)
        processItalicPattern(Self.italicUnderscorePattern, in: attributedString, baseFont: baseFont)
    }
    
    private func processItalicPattern(_ pattern: NSRegularExpression, in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let range = NSRange(location: 0, length: string.count)
        
        let matches = pattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            if let contentSwiftRange = Range(contentRange, in: string) {
                let content = String(string[contentSwiftRange])
                let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: content,
                    attributes: [.font: italicFont]
                ))
            }
        }
    }
    
    private func processCode(in attributedString: NSMutableAttributedString, codeFont: NSFont) {
        let string = attributedString.string
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.codePattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            if let contentSwiftRange = Range(contentRange, in: string) {
                let content = String(string[contentSwiftRange])
                
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: content,
                    attributes: [
                        .font: codeFont,
                        .backgroundColor: NSColor.controlBackgroundColor
                    ]
                ))
            }
        }
    }
    
    private func processLinks(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.linkPattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            
            if let textSwiftRange = Range(textRange, in: string),
               let urlSwiftRange = Range(urlRange, in: string) {
                let linkText = String(string[textSwiftRange])
                let linkURL = String(string[urlSwiftRange])
                
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: linkText,
                    attributes: [
                        .font: baseFont,
                        .foregroundColor: NSColor.linkColor,
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .link: linkURL
                    ]
                ))
            }
        }
    }
    
    private func processAutoLinks(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        
        // Safety check: skip processing if string is too long to prevent hangs
        guard string.count < 10000 else { return }
        
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.autoLinkPattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let urlRange = match.range(at: 1)
            
            if let urlSwiftRange = Range(urlRange, in: string) {
                let url = String(string[urlSwiftRange])
                
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: url,
                    attributes: [
                        .font: baseFont,
                        .foregroundColor: NSColor.linkColor,
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .link: url
                    ]
                ))
            }
        }
    }
    
    private func processBareURLs(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        
        // Safety check: skip processing if string is too long to prevent hangs
        guard string.count < 10000 else { return }
        
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.bareURLPattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let urlRange = match.range(at: 1)
            
            if let urlSwiftRange = Range(urlRange, in: string) {
                let url = String(string[urlSwiftRange])
                
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: url,
                    attributes: [
                        .font: baseFont,
                        .foregroundColor: NSColor.linkColor,
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .link: url
                    ]
                ))
            }
        }
    }
    
    private func processEmojis(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        
        // Safety check: skip processing if string is too long to prevent hangs
        guard string.count < 10000 else { return }
        
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.emojiPattern.matches(in: string, range: range)
        
        // Simple emoji mapping for common emojis
        let emojiMap: [String: String] = [
            "smile": "😄", "laugh": "😆", "grin": "😁", "joy": "😂",
            "heart": "❤️", "thumbsup": "👍", "+1": "👍", "thumbsdown": "👎", "-1": "👎",
            "fire": "🔥", "rocket": "🚀", "star": "⭐", "check": "✅",
            "x": "❌", "warning": "⚠️", "info": "ℹ️", "question": "❓",
            "exclamation": "❗", "tada": "🎉", "clap": "👏", "wave": "👋"
        ]
        
        for match in matches.reversed() {
            let fullRange = match.range
            let emojiNameRange = match.range(at: 1)
            
            if let emojiNameSwiftRange = Range(emojiNameRange, in: string) {
                let emojiName = String(string[emojiNameSwiftRange])
                
                if let emoji = emojiMap[emojiName] {
                    attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                        string: emoji,
                        attributes: [.font: baseFont]
                    ))
                }
                // If emoji not found in map, leave the original :emoji: syntax
            }
        }
    }
    
    private func processImages(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let range = NSRange(location: 0, length: string.count)
        
        let matches = Self.imagePattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let altRange = match.range(at: 1)
            
            if let altSwiftRange = Range(altRange, in: string) {
                let altText = String(string[altSwiftRange])
                let placeholder = altText.isEmpty ? "Image" : altText
                
                // For RTF, represent images as styled text placeholders
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: "[Image: \(placeholder)]",
                    attributes: [
                        .font: baseFont.withTraits(.italic),
                        .foregroundColor: NSColor.secondaryLabelColor
                    ]
                ))
            }
        }
    }
    
    // MARK: - Escape Sequence Processing
    
    /// Preprocess escape sequences by converting them to literal characters
    /// This should be done before any other markdown processing
    private func preprocessEscapes(_ text: String) -> String {
        // Safety check for input length
        guard text.count < 50000 else { return text }
        
        return Self.escapePattern.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.count),
            withTemplate: "$1"
        )
    }
}

// MARK: - NSFont Extension
extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
