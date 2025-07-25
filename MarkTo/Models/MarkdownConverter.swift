import Foundation
import AppKit

// MARK: - Markdown Conversion Error
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

// MARK: - Refactored Markdown Converter
/// Main interface for converting markdown to RTF using the new modular architecture
class MarkdownConverter {
    
    private let parser: MarkdownParser
    
    // Configuration options
    struct Configuration {
        let baseFont: NSFont
        let codeFont: NSFont
        let preserveWhitespace: Bool
        let strictMode: Bool
        
        static let `default` = Configuration(
            baseFont: NSFont.systemFont(ofSize: 14),
            codeFont: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            preserveWhitespace: false,
            strictMode: false
        )
    }
    
    init(configuration: Configuration = .default) {
        self.parser = MarkdownParser(
            baseFont: configuration.baseFont,
            codeFont: configuration.codeFont
        )
    }
    
    // MARK: - Public API
    
    /// Convert markdown text to RTF
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Result containing NSAttributedString or error
    func convertToRTF(_ markdown: String) -> Result<NSAttributedString, MarkdownConversionError> {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        let parseResult = parser.parse(markdown)
        
        switch parseResult {
        case .success(let attributedString):
            return .success(attributedString)
        case .failure(let parsingError):
            return .failure(.parsingError(parsingError.localizedDescription))
        }
    }
    
    /// Convert markdown to RTF with additional processing options
    /// - Parameters:
    ///   - markdown: Raw markdown text
    ///   - options: Additional processing options
    /// - Returns: Result containing NSAttributedString or error
    func convertToRTF(_ markdown: String, options: ConversionOptions) -> Result<NSAttributedString, MarkdownConversionError> {
        var processedMarkdown = markdown
        
        // Pre-process based on options
        if options.normalizeWhitespace {
            processedMarkdown = normalizeWhitespace(processedMarkdown)
        }
        
        if options.removeTrailingWhitespace {
            processedMarkdown = removeTrailingWhitespace(processedMarkdown)
        }
        
        return convertToRTF(processedMarkdown)
    }
    
    // MARK: - Conversion Options
    
    struct ConversionOptions {
        let normalizeWhitespace: Bool
        let removeTrailingWhitespace: Bool
        let preserveCodeBlockLanguages: Bool
        
        static let `default` = ConversionOptions(
            normalizeWhitespace: true,
            removeTrailingWhitespace: true,
            preserveCodeBlockLanguages: false
        )
    }
    
    // MARK: - Utility Methods
    
    private func normalizeWhitespace(_ text: String) -> String {
        // Convert multiple spaces to single spaces (except in code blocks)
        return text.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
    }
    
    private func removeTrailingWhitespace(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let trimmedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        return trimmedLines.joined(separator: "\n")
    }
}
