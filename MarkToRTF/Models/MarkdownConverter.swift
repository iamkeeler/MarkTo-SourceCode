import Foundation
import AppKit

enum MarkdownConversionError: Error, LocalizedError {
    case invalidInput
    case conversionFailed
    case rtfGenerationFailed
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid markdown input"
        case .conversionFailed:
            return "Failed to convert markdown"
        case .rtfGenerationFailed:
            return "Failed to generate RTF"
        case .parsingError(let details):
            return "Parsing error: \(details)"
        }
    }
}

class MarkdownConverter {
    
    // MARK: - Public Methods
    
    func convertToRTF(_ markdown: String) -> Result<String, MarkdownConversionError> {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            // Convert markdown to attributed string
            let attributedString = try parseMarkdown(markdown)
            
            // Generate RTF from attributed string
            let rtfData = try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            
            guard let rtfString = String(data: rtfData, encoding: .utf8) else {
                return .failure(.rtfGenerationFailed)
            }
            
            return .success(rtfString)
        } catch {
            if let conversionError = error as? MarkdownConversionError {
                return .failure(conversionError)
            } else {
                return .failure(.parsingError(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func parseMarkdown(_ markdown: String) throws -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: .newlines)
        
        // Font configuration
        let baseFont = NSFont.systemFont(ofSize: 14)
        let codeFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        var isInCodeBlock = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                attributedString.append(NSAttributedString(string: "\n"))
                continue
            }
            
            let lineString = NSMutableAttributedString()
            
            // Handle code blocks
            if trimmedLine.hasPrefix("```") {
                isInCodeBlock.toggle()
                if !isInCodeBlock {
                    lineString.append(NSAttributedString(string: "\n"))
                }
                attributedString.append(lineString)
                continue
            }
            
            if isInCodeBlock {
                lineString.append(NSAttributedString(
                    string: line,
                    attributes: [
                        .font: codeFont,
                        .foregroundColor: NSColor.textColor,
                        .backgroundColor: NSColor.controlBackgroundColor
                    ]
                ))
            } else {
                // Parse different markdown elements
                if let parsedLine = parseMarkdownLine(trimmedLine, baseFont: baseFont, codeFont: codeFont) {
                    lineString.append(parsedLine)
                } else {
                    // Fallback to plain text
                    lineString.append(NSAttributedString(string: trimmedLine, attributes: [.font: baseFont]))
                }
            }
            
            attributedString.append(lineString)
            attributedString.append(NSAttributedString(string: "\n"))
        }
        
        return attributedString
    }
    
    private func parseMarkdownLine(_ line: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString? {
        if line.hasPrefix("# ") {
            return createHeading(String(line.dropFirst(2)), level: 1)
        } else if line.hasPrefix("## ") {
            return createHeading(String(line.dropFirst(3)), level: 2)
        } else if line.hasPrefix("### ") {
            return createHeading(String(line.dropFirst(4)), level: 3)
        } else if line.hasPrefix("#### ") {
            return createHeading(String(line.dropFirst(5)), level: 4)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
            let text = String(line.dropFirst(2))
            let bulletPoint = NSMutableAttributedString(string: "• ")
            bulletPoint.append(parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont))
            return bulletPoint
        } else if let numberMatch = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            let number = String(line[numberMatch])
            let text = String(line[numberMatch.upperBound...])
            let numberedItem = NSMutableAttributedString(string: number)
            numberedItem.append(parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont))
            return numberedItem
        } else {
            return parseInlineMarkdown(line, baseFont: baseFont, codeFont: codeFont)
        }
    }
    
    private func createHeading(_ text: String, level: Int) -> NSAttributedString {
        let fontSize: CGFloat
        switch level {
        case 1: fontSize = 24
        case 2: fontSize = 20
        case 3: fontSize = 16
        case 4: fontSize = 14
        default: fontSize = 14
        }
        
        return NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.textColor
            ]
        )
    }
    
    private func parseInlineMarkdown(_ text: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Use NSScanner for more efficient parsing
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            // Look for bold (**text**)
            if scanner.scanString("**") != nil {
                if let boldText = scanUntilPattern(scanner, pattern: "**") {
                    result.append(NSAttributedString(
                        string: boldText,
                        attributes: [.font: NSFont.boldSystemFont(ofSize: baseFont.pointSize)]
                    ))
                } else {
                    result.append(NSAttributedString(string: "**", attributes: [.font: baseFont]))
                }
            }
            // Look for italic (*text*)
            else if scanner.scanString("*") != nil {
                if let italicText = scanUntilPattern(scanner, pattern: "*") {
                    let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                    result.append(NSAttributedString(
                        string: italicText,
                        attributes: [.font: italicFont]
                    ))
                } else {
                    result.append(NSAttributedString(string: "*", attributes: [.font: baseFont]))
                }
            }
            // Look for code (`text`)
            else if scanner.scanString("`") != nil {
                if let codeText = scanUntilPattern(scanner, pattern: "`") {
                    result.append(NSAttributedString(
                        string: codeText,
                        attributes: [
                            .font: codeFont,
                            .backgroundColor: NSColor.controlBackgroundColor
                        ]
                    ))
                } else {
                    result.append(NSAttributedString(string: "`", attributes: [.font: baseFont]))
                }
            }
            // Regular text
            else if let regularText = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "*`")) {
                result.append(NSAttributedString(string: regularText, attributes: [.font: baseFont]))
            } else {
                // Scan single character if no patterns found
                let currentIndex = scanner.currentIndex
                if currentIndex < text.endIndex {
                    let char = String(text[currentIndex])
                    result.append(NSAttributedString(string: char, attributes: [.font: baseFont]))
                    scanner.currentIndex = text.index(after: currentIndex)
                }
            }
        }
        
        return result
    }
    
    private func scanUntilPattern(_ scanner: Scanner, pattern: String) -> String? {
        guard let content = scanner.scanUpToString(pattern) else { return nil }
        guard scanner.scanString(pattern) != nil else { return nil }
        return content
    }
}
