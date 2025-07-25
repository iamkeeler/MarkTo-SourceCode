import Foundation
import AppKit

// MARK: - Markdown Parser Errors
enum MarkdownParsingError: Error, LocalizedError {
    case invalidInput
    case parsingFailed(String)
    case memoryError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid markdown input"
        case .parsingFailed(let details):
            return "Parsing failed: \(details)"
        case .memoryError:
            return "Memory allocation error during parsing"
        }
    }
}

// MARK: - Main Markdown Parser
/// Orchestrates the parsing of markdown content using specialized processors
class MarkdownParser {
    
    // Component processors
    private let inlineProcessor: InlineProcessor
    private let listProcessor: ListProcessor
    private let blockProcessor: BlockProcessor
    private let tableProcessor: TableProcessor
    
    // Configuration
    private let baseFont: NSFont
    private let codeFont: NSFont
    
    init(baseFont: NSFont = NSFont.systemFont(ofSize: 14),
         codeFont: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)) {
        
        self.baseFont = baseFont
        self.codeFont = codeFont
        
        // Initialize processors
        self.inlineProcessor = InlineProcessor()
        self.listProcessor = ListProcessor(inlineProcessor: inlineProcessor)
        self.blockProcessor = BlockProcessor(inlineProcessor: inlineProcessor)
        self.tableProcessor = TableProcessor(inlineProcessor: inlineProcessor)
    }
    
    // MARK: - Public API
    
    /// Parse markdown text into NSAttributedString
    /// - Parameter markdown: Raw markdown text
    /// - Returns: Result containing attributed string or error
    func parse(_ markdown: String) -> Result<NSAttributedString, MarkdownParsingError> {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            let result = try parseMarkdown(markdown)
            return .success(result)
        } catch {
            if let parsingError = error as? MarkdownParsingError {
                return .failure(parsingError)
            } else {
                return .failure(.parsingFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Core Parsing Logic
    
    private func parseMarkdown(_ markdown: String) throws -> NSAttributedString {
        let lines = markdown.components(separatedBy: .newlines)
        let context = ParsingContext(baseFont: baseFont, codeFont: codeFont)
        context.setTotalLines(lines.count)
        
        let result = NSMutableAttributedString()
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            context.currentLineIndex = i
            
            // Handle empty lines
            if trimmedLine.isEmpty {
                handleEmptyLine(result, context: context)
                i += 1
                continue
            }
            
            // Handle code blocks (fenced)
            if trimmedLine.hasPrefix("```") {
                let codeBlockResult = parseCodeBlock(lines: lines, startIndex: i, context: context)
                result.append(codeBlockResult.content)
                i = codeBlockResult.nextIndex
                continue
            }
            
            // Skip processing if we're inside a code block
            if context.isInCodeBlock {
                result.append(NSAttributedString(
                    string: line,
                    attributes: [
                        .font: context.codeFont,
                        .foregroundColor: NSColor.textColor,
                        .backgroundColor: NSColor.controlBackgroundColor
                    ]
                ))
                result.append(NSAttributedString(string: "\n"))
                i += 1
                continue
            }
            
            // Parse the line based on its type
            let lineContent = parseLine(line, context: context, lines: lines, currentIndex: &i)
            result.append(lineContent)
            result.append(NSAttributedString(string: "\n"))
            
            i += 1
        }
        
        return result
    }
    
    // MARK: - Line Parsing
    
    private func parseLine(_ line: String, context: ParsingContext, lines: [String], currentIndex: inout Int) -> NSAttributedString {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Check for tables first (they can contain other markdown)
        if tableProcessor.isTableRow(trimmedLine) {
            let tableResult = tableProcessor.parseTable(lines: lines, startIndex: currentIndex, context: context)
            currentIndex = tableResult.endIndex - 1 // Adjust for loop increment
            context.listContext.reset() // Tables break lists
            return tableResult.content
        }
        
        // Check for horizontal rules
        if blockProcessor.isHorizontalRule(trimmedLine) {
            context.listContext.reset()
            return blockProcessor.createHorizontalRule()
        }
        
        // Check for headers
        if let headerLevel = blockProcessor.getHeaderLevel(trimmedLine) {
            let headerText = blockProcessor.getHeaderText(trimmedLine)
            context.listContext.reset()
            return blockProcessor.createHeading(headerText, level: headerLevel, context: context)
        }
        
        // Check for blockquotes
        if trimmedLine.hasPrefix("> ") {
            let text = String(trimmedLine.dropFirst(2))
            context.listContext.reset()
            return blockProcessor.createBlockquote(text, context: context)
        }
        
        // Check for unordered lists
        if let listMatch = trimmedLine.range(of: #"^(\s*)([-*+])\s+"#, options: .regularExpression) {
            let prefix = String(trimmedLine[..<listMatch.upperBound])
            let indentLevel = listProcessor.calculateIndentLevel(prefix)
            let text = String(trimmedLine[listMatch.upperBound...])
            context.listContext.updateWith(level: indentLevel, type: .unordered)
            return listProcessor.createUnorderedListItem(text, level: indentLevel, context: context)
        }
        
        // Check for ordered lists
        if let numberMatch = trimmedLine.range(of: #"^(\s*)(\d+)\.\s+"#, options: .regularExpression) {
            let prefix = String(trimmedLine[..<numberMatch.upperBound])
            let indentLevel = listProcessor.calculateIndentLevel(prefix)
            let numberText = String(trimmedLine[numberMatch]).trimmingCharacters(in: .whitespaces)
            let number = String(numberText.dropLast()) // Remove the dot
            let text = String(trimmedLine[numberMatch.upperBound...])
            context.listContext.updateWith(level: indentLevel, type: .ordered)
            return listProcessor.createOrderedListItem(text, number: number, level: indentLevel, context: context)
        }
        
        // Check for task lists
        if let taskMatch = trimmedLine.range(of: #"^(\s*)([-*+])\s*\[([ xX])\]\s+"#, options: .regularExpression) {
            let prefix = String(trimmedLine[..<taskMatch.upperBound])
            let indentLevel = listProcessor.calculateIndentLevel(prefix)
            let checkbox = String(trimmedLine[taskMatch])
            let isChecked = checkbox.contains("x") || checkbox.contains("X")
            let text = String(trimmedLine[taskMatch.upperBound...])
            context.listContext.updateWith(level: indentLevel, type: .task)
            return listProcessor.createTaskListItem(text, isChecked: isChecked, level: indentLevel, context: context)
        }
        
        // Check for definition lists
        if trimmedLine.hasPrefix(": ") {
            let text = String(trimmedLine.dropFirst(2))
            context.listContext.updateWith(level: 1, type: .definition)
            return blockProcessor.createDefinition(text, context: context)
        }
        
        // Check for list continuation
        if listProcessor.isListContinuation(line, listContext: context.listContext) {
            let indentLevel = context.listContext.currentLevel
            context.listContext.setContinuation()
            return listProcessor.createListContinuation(trimmedLine, level: indentLevel, context: context)
        }
        
        // Regular paragraph - this breaks lists unless it's clearly a continuation
        context.listContext.reset()
        return processRegularText(line, context: context)
    }
    
    // MARK: - Specialized Parsing Methods
    
    private func handleEmptyLine(_ result: NSMutableAttributedString, context: ParsingContext) {
        if context.listContext.isInList {
            // Add reduced spacing within lists
            result.append(NSAttributedString(string: "\n"))
        } else {
            result.append(NSAttributedString(string: "\n"))
        }
    }
    
    private func parseCodeBlock(lines: [String], startIndex: Int, context: ParsingContext) -> (content: NSAttributedString, nextIndex: Int) {
        let firstLine = lines[startIndex].trimmingCharacters(in: .whitespaces)
        
        if !context.isInCodeBlock {
            // Starting code block
            context.isInCodeBlock = true
            context.codeBlockLanguage = String(firstLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            if context.codeBlockLanguage?.isEmpty == true {
                context.codeBlockLanguage = nil
            }
            context.listContext.reset() // Code blocks break lists
            
            // Look for the closing ```
            var codeLines: [String] = []
            var i = startIndex + 1
            
            while i < lines.count {
                let line = lines[i]
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    // Found closing marker
                    context.isInCodeBlock = false
                    context.codeBlockLanguage = nil
                    let content = blockProcessor.createCodeBlock(codeLines, language: context.codeBlockLanguage, context: context)
                    return (content: content, nextIndex: i + 1)
                } else {
                    codeLines.append(line)
                }
                i += 1
            }
            
            // No closing marker found - treat as regular text
            context.isInCodeBlock = false
            let content = inlineProcessor.processInlineMarkdown(firstLine, baseFont: context.baseFont, codeFont: context.codeFont)
            return (content: content, nextIndex: startIndex + 1)
        } else {
            // Ending code block
            context.isInCodeBlock = false
            context.codeBlockLanguage = nil
            return (content: NSAttributedString(string: ""), nextIndex: startIndex + 1)
        }
    }
    
    // MARK: - Text Processing Helpers
    
    private func processRegularText(_ line: String, context: ParsingContext) -> NSAttributedString {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Check for double-space line break (markdown line break)
        if line.hasSuffix("  ") && !trimmedLine.isEmpty {
            let textWithoutTrailingSpaces = String(line.dropLast(2))
            let content = inlineProcessor.processInlineMarkdown(textWithoutTrailingSpaces, baseFont: context.baseFont, codeFont: context.codeFont)
            let result = NSMutableAttributedString()
            result.append(content)
            result.append(NSAttributedString(string: "\n"))  // Hard line break
            return result
        }
        
        // Regular paragraph text
        return inlineProcessor.processInlineMarkdown(trimmedLine, baseFont: context.baseFont, codeFont: context.codeFont)
    }
}
