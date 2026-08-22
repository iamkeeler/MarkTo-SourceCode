import Foundation
import AppKit

// MARK: - Inline Processor
/// Handles inline markdown formatting: bold, italic, code, links, etc.
final class InlineProcessor {
    private struct ProtectedSpan {
        let token: String
        let content: String
    }

    private let formatting: FormattingSnapshot
    
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

    init(formatting: FormattingSnapshot = .defaults) {
        self.formatting = formatting
    }
    
    /// Process inline markdown formatting in text
    /// - Parameters:
    ///   - text: Raw text with markdown formatting
    ///   - baseFont: Font to use for regular text
    ///   - codeFont: Font to use for code spans
    /// - Returns: NSAttributedString with applied formatting
    func processInlineMarkdown(_ text: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        // Protect escaped punctuation and code before running patterns that
        // would otherwise interpret their contents as Markdown.
        let escaped = protectMatches(in: text, pattern: Self.escapePattern, prefix: "ESC")
        let code = protectMatches(in: escaped.text, pattern: Self.codePattern, prefix: "CODE")
        let result = NSMutableAttributedString(string: code.text, attributes: [.font: baseFont])
        
        // Process in specific order to handle overlapping patterns correctly
        processStrikethrough(in: result, baseFont: baseFont)
        processBold(in: result, baseFont: baseFont)
        processItalic(in: result, baseFont: baseFont)
        processImages(in: result, baseFont: baseFont)
        processLinks(in: result, baseFont: baseFont)
        processAutoLinks(in: result, baseFont: baseFont)
        processBareURLs(in: result, baseFont: baseFont)
        processEmojis(in: result, baseFont: baseFont)

        restoreCodeSpans(code.spans, in: result, codeFont: codeFont)
        restoreLiteralSpans(escaped.spans, in: result, fallbackFont: baseFont)
        
        return result
    }
    
    // MARK: - Private Processing Methods
    
    private func processStrikethrough(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = Self.strikethroughPattern.matches(in: string, range: range)
        
        // Process in reverse order to maintain indices
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            let content = nsString.substring(with: contentRange)
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
    
    private func processBold(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        // Process ** bold ** first
        processBoldPattern(Self.boldPattern, in: attributedString, baseFont: baseFont)
        
        // Then process __ bold __
        processBoldPattern(Self.boldUnderscorePattern, in: attributedString, baseFont: baseFont)
    }
    
    private func processBoldPattern(_ pattern: NSRegularExpression, in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = pattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            let content = nsString.substring(with: contentRange)
            let boldFormatting = formatting.formatting(for: .bold)
            let boldFont = NSFont.systemFont(
                ofSize: boldFormatting.fontSize,
                weight: boldFormatting.fontWeight.nsWeight
            )
                
            attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                string: content,
                attributes: [.font: boldFont]
            ))
        }
    }
    
    private func processItalic(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        processItalicPattern(Self.italicPattern, in: attributedString, baseFont: baseFont)
        processItalicPattern(Self.italicUnderscorePattern, in: attributedString, baseFont: baseFont)
    }
    
    private func processItalicPattern(_ pattern: NSRegularExpression, in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = pattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let contentRange = match.range(at: 1)
            
            let content = nsString.substring(with: contentRange)
            let italicFormatting = formatting.formatting(for: .italic)
            let italicBaseFont = NSFont.systemFont(
                ofSize: italicFormatting.fontSize,
                weight: italicFormatting.fontWeight.nsWeight
            )
            let italicFont = NSFontManager.shared.convert(italicBaseFont, toHaveTrait: .italicFontMask)
                
            attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                string: content,
                attributes: [.font: italicFont]
            ))
        }
    }
    
    private func processLinks(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = Self.linkPattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            
            let linkText = nsString.substring(with: textRange)
            let linkURL = nsString.substring(with: urlRange)
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
    
    private func processAutoLinks(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        
        // Safety check: skip processing if string is too long to prevent hangs
        guard string.count < 10000 else { return }
        
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = Self.autoLinkPattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let urlRange = match.range(at: 1)
            
            let url = nsString.substring(with: urlRange)
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
    
    private func processBareURLs(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        
        // Safety check: skip processing if string is too long to prevent hangs
        guard string.count < 10000 else { return }
        
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = Self.bareURLPattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let urlRange = match.range(at: 1)
            
            let url = nsString.substring(with: urlRange)
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
    
    private func processEmojis(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        
        // Safety check: skip processing if string is too long to prevent hangs
        guard string.count < 10000 else { return }
        
        let range = NSRange(location: 0, length: nsString.length)
        
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
            
            let emojiName = nsString.substring(with: emojiNameRange)
            if let emoji = emojiMap[emojiName] {
                attributedString.replaceCharacters(in: fullRange, with: NSAttributedString(
                    string: emoji,
                    attributes: [.font: baseFont]
                ))
                // If emoji not found in map, leave the original :emoji: syntax
            }
        }
    }
    
    private func processImages(in attributedString: NSMutableAttributedString, baseFont: NSFont) {
        let string = attributedString.string
        let nsString = string as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = Self.imagePattern.matches(in: string, range: range)
        
        for match in matches.reversed() {
            let fullRange = match.range
            let altRange = match.range(at: 1)
            
            let altText = nsString.substring(with: altRange)
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
    
    // MARK: - Escape Sequence Processing
    
    private func protectMatches(
        in text: String,
        pattern: NSRegularExpression,
        prefix: String
    ) -> (text: String, spans: [ProtectedSpan]) {
        let source = text as NSString
        let mutable = NSMutableString(string: text)
        let matches = pattern.matches(
            in: text,
            range: NSRange(location: 0, length: source.length)
        )
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        var spans: [ProtectedSpan] = []

        for (index, match) in matches.reversed().enumerated() {
            let token = "\u{E000}\(prefix)\(nonce)X\(index)\u{E001}"
            let content = source.substring(with: match.range(at: 1))
            mutable.replaceCharacters(in: match.range, with: token)
            spans.append(ProtectedSpan(token: token, content: content))
        }

        return (mutable as String, spans)
    }

    private func restoreCodeSpans(
        _ spans: [ProtectedSpan],
        in attributedString: NSMutableAttributedString,
        codeFont: NSFont
    ) {
        for span in spans {
            let range = (attributedString.string as NSString).range(of: span.token)
            guard range.location != NSNotFound else { continue }
            attributedString.replaceCharacters(
                in: range,
                with: NSAttributedString(
                    string: span.content,
                    attributes: [
                        .font: codeFont,
                        .backgroundColor: NSColor.controlBackgroundColor
                    ]
                )
            )
        }
    }

    private func restoreLiteralSpans(
        _ spans: [ProtectedSpan],
        in attributedString: NSMutableAttributedString,
        fallbackFont: NSFont
    ) {
        for span in spans {
            let range = (attributedString.string as NSString).range(of: span.token)
            guard range.location != NSNotFound else { continue }
            let attributes = range.location < attributedString.length
                ? attributedString.attributes(at: range.location, effectiveRange: nil)
                : [.font: fallbackFont]
            attributedString.replaceCharacters(
                in: range,
                with: NSAttributedString(string: span.content, attributes: attributes)
            )
        }
    }
}

// MARK: - NSFont Extension
extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
