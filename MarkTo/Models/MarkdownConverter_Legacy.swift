import Foundation
import AppKit

// MARK: - List Context Tracking
class ListContext {
    var isInList: Bool = false
    var currentLevel: Int = 0
    var lastListType: ListType = .unordered
    var lastWasListItem: Bool = false
    
    enum ListType {
        case unordered, ordered, task, definition
    }
    
    func updateWith(level: Int, type: ListType) {
        isInList = true
        currentLevel = level
        lastListType = type
        lastWasListItem = true
    }
    
    func reset() {
        isInList = false
        currentLevel = 0
        lastWasListItem = false
    }
    
    func setContinuation() {
        lastWasListItem = false
    }
}

// MARK: - RTF Table Generator
class RTFTableGenerator {
    
    struct TableData {
        let headerRow: [String]
        let dataRows: [[String]]
        let hasHeader: Bool
        
        var maxColumns: Int {
            max(headerRow.count, dataRows.map { $0.count }.max() ?? 0)
        }
    }
    
    // Generate RTF table with proper table structure
    static func generateRTFTable(from tableData: TableData) -> NSAttributedString {
        // Try HTML table approach - many apps recognize HTML table structure better than RTF
        let htmlTable = generateHTMLTable(from: tableData)
        
        // Convert HTML to NSAttributedString
        if let htmlData = htmlTable.data(using: .utf8),
           let attributedString = try? NSAttributedString(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
           ) {
            return attributedString
        } else {
            // HTML parsing failed, use enhanced plain text table
            return generateEnhancedPlainTextTable(from: tableData)
        }
    }
    
    // Generate HTML table structure
    private static func generateHTMLTable(from tableData: TableData) -> String {
        var html = "<table border='1' cellpadding='4' cellspacing='0' style='border-collapse: collapse;'>"
        
        // Header row
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            html += "<tr>"
            for cell in tableData.headerRow {
                let escapedCell = cell.replacingOccurrences(of: "&", with: "&amp;")
                                     .replacingOccurrences(of: "<", with: "&lt;")
                                     .replacingOccurrences(of: ">", with: "&gt;")
                html += "<th style='font-weight: bold; background-color: #f0f0f0;'>\(escapedCell)</th>"
            }
            html += "</tr>"
        }
        
        // Data rows
        for row in tableData.dataRows {
            html += "<tr>"
            for cell in row {
                let escapedCell = cell.replacingOccurrences(of: "&", with: "&amp;")
                                     .replacingOccurrences(of: "<", with: "&lt;")
                                     .replacingOccurrences(of: ">", with: "&gt;")
                html += "<td>\(escapedCell)</td>"
            }
            
            // Fill empty cells to match max columns
            for _ in row.count..<tableData.maxColumns {
                html += "<td></td>"
            }
            html += "</tr>"
        }
        
        html += "</table>"
        return html
    }
    
    // Create a complete RTF document with proper table structure
    private static func createRTFDocument(from tableData: TableData) -> String {
        var rtf = "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}\\f0\\fs24 "
        
        // Calculate column widths in twips (1440 twips = 1 inch)
        let totalWidth = 8000 // Total table width in twips
        let columnWidth = totalWidth / tableData.maxColumns
        
        // Header row
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            rtf += generateRTFTableRow(
                cells: tableData.headerRow,
                columnWidth: columnWidth,
                maxColumns: tableData.maxColumns,
                isHeader: true
            )
        }
        
        // Data rows
        for row in tableData.dataRows {
            rtf += generateRTFTableRow(
                cells: row,
                columnWidth: columnWidth,
                maxColumns: tableData.maxColumns,
                isHeader: false
            )
        }
        
        rtf += "\\par}"
        return rtf
    }
    
    // Generate a single RTF table row with proper table formatting
    private static func generateRTFTableRow(
        cells: [String],
        columnWidth: Int,
        maxColumns: Int,
        isHeader: Bool
    ) -> String {
        var rtf = ""
        
        // Start table row
        rtf += "\\trowd\\trgaph108\\trleft-108"
        
        // Define cell positions and borders
        for i in 1...maxColumns {
            let position = i * columnWidth
            rtf += "\\clbrdrt\\brdrs\\brdrw10\\brdrcf1"  // Top border
            rtf += "\\clbrdrl\\brdrs\\brdrw10\\brdrcf1"  // Left border
            rtf += "\\clbrdrb\\brdrs\\brdrw10\\brdrcf1"  // Bottom border
            rtf += "\\clbrdrr\\brdrs\\brdrw10\\brdrcf1"  // Right border
            rtf += "\\cellx\(position)"
        }
        
        // Add cell content
        for i in 0..<maxColumns {
            let cellContent = i < cells.count ? cells[i] : ""
            let escapedContent = escapeRTFString(cellContent)
            
            if isHeader {
                rtf += "{\\b \(escapedContent)}\\cell"
            } else {
                rtf += "\(escapedContent)\\cell"
            }
        }
        
        rtf += "\\row"
        return rtf
    }
    
    // Helper function to escape RTF special characters
    private static func escapeRTFString(_ string: String) -> String {
        return string.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "{", with: "\\{")
                    .replacingOccurrences(of: "}", with: "\\}")
                    .replacingOccurrences(of: "\n", with: "\\par ")
    }
    
    // Generate RTF table code manually
    private static func generateRTFTableCode(from tableData: TableData) -> String {
        var rtf = "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}\\f0\\fs24 "
        
        // Calculate column widths (equal width for all columns)
        let columnWidth = 9000 / tableData.maxColumns // RTF units
        
        // Header row
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            rtf += generateRTFTableRow(
                cells: tableData.headerRow,
                columnWidth: columnWidth,
                maxColumns: tableData.maxColumns,
                isHeader: true
            )
        }
        
        // Data rows
        for row in tableData.dataRows {
            rtf += generateRTFTableRow(
                cells: row,
                columnWidth: columnWidth,
                maxColumns: tableData.maxColumns,
                isHeader: false
            )
        }
        
        rtf += "\\par}"
        return rtf
    }
    
    // Generate enhanced plain text table with better formatting
    private static func generateEnhancedPlainTextTable(from tableData: TableData) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Calculate column widths
        var columnWidths: [Int] = []
        let allRows = tableData.hasHeader ? [tableData.headerRow] + tableData.dataRows : tableData.dataRows
        
        for columnIndex in 0..<tableData.maxColumns {
            let maxWidth = allRows.map { row in
                columnIndex < row.count ? row[columnIndex].count : 0
            }.max() ?? 0
            columnWidths.append(max(maxWidth, 3)) // Minimum width of 3
        }
        
        // Header row
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            let headerString = NSMutableAttributedString()
            for (index, cell) in tableData.headerRow.enumerated() {
                let paddedCell = cell.padding(toLength: columnWidths[index], withPad: " ", startingAt: 0)
                let cellString = NSAttributedString(string: paddedCell, attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 13)
                ])
                headerString.append(cellString)
                
                if index < tableData.headerRow.count - 1 {
                    headerString.append(NSAttributedString(string: " │ "))
                }
            }
            result.append(headerString)
            result.append(NSAttributedString(string: "\n"))
            
            // Separator line
            var separatorLine = ""
            for (index, width) in columnWidths.enumerated() {
                separatorLine += String(repeating: "─", count: width)
                if index < columnWidths.count - 1 {
                    separatorLine += "─┼─"
                }
            }
            result.append(NSAttributedString(string: separatorLine + "\n"))
        }
        
        // Data rows
        for row in tableData.dataRows {
            let rowString = NSMutableAttributedString()
            for (index, cell) in row.enumerated() {
                let columnIndex = min(index, columnWidths.count - 1)
                let paddedCell = cell.padding(toLength: columnWidths[columnIndex], withPad: " ", startingAt: 0)
                let cellString = NSAttributedString(string: paddedCell, attributes: [
                    .font: NSFont.systemFont(ofSize: 13)
                ])
                rowString.append(cellString)
                
                if index < row.count - 1 && index < columnWidths.count - 1 {
                    rowString.append(NSAttributedString(string: " │ "))
                }
            }
            result.append(rowString)
            result.append(NSAttributedString(string: "\n"))
        }
        
        return result
    }
}

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
    
    func convertToRTF(_ markdown: String) -> Result<NSAttributedString, MarkdownConversionError> {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidInput)
        }
        
        do {
            // Convert markdown to attributed string
            let attributedString = try parseMarkdown(markdown)
            return .success(attributedString)
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
        var codeBlockLanguage: String? = nil
        
        var i = 0
        var listContext: ListContext = ListContext() // Track list state
        
        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                // Handle empty lines in list context
                if listContext.isInList {
                    // Add reduced spacing within lists
                    attributedString.append(NSAttributedString(string: "\n"))
                } else {
                    attributedString.append(NSAttributedString(string: "\n"))
                }
                i += 1
                continue
            }
            
            let lineString = NSMutableAttributedString()
            
            // Handle code blocks with language specification
            if trimmedLine.hasPrefix("```") {
                listContext.reset() // Code blocks break lists
                if !isInCodeBlock {
                    // Starting code block
                    codeBlockLanguage = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    if codeBlockLanguage?.isEmpty == true {
                        codeBlockLanguage = nil
                    }
                } else {
                    // Ending code block
                    codeBlockLanguage = nil
                }
                isInCodeBlock.toggle()
                if !isInCodeBlock {
                    lineString.append(NSAttributedString(string: "\n"))
                }
                attributedString.append(lineString)
                i += 1
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
                listContext.reset() // Code blocks break lists
            } else {
                // Check for horizontal rules
                if isHorizontalRule(trimmedLine) {
                    lineString.append(createHorizontalRule())
                    listContext.reset() // Horizontal rules break lists
                }
                // Check for tables
                else if isTableRow(trimmedLine) {
                    let tableResult = parseTableStructure(lines: lines, startIndex: i)
                    let rtfTable = RTFTableGenerator.generateRTFTable(from: tableResult.tableData)
                    lineString.append(rtfTable)
                    i = tableResult.endIndex - 1 // Skip processed table rows
                    listContext.reset() // Tables break lists
                }
                // Parse different markdown elements with list context awareness
                else if let parsedLine = parseMarkdownLineWithContext(line, baseFont: baseFont, codeFont: codeFont, listContext: &listContext) {
                    lineString.append(parsedLine)
                } else {
                    // Fallback to plain text
                    listContext.reset()
                    lineString.append(NSAttributedString(string: trimmedLine, attributes: [.font: baseFont]))
                }
            }
            
            attributedString.append(lineString)
            attributedString.append(NSAttributedString(string: "\n"))
            i += 1
        }
        
        return attributedString
    }
    
    private func parseMarkdownLineWithContext(_ line: String, baseFont: NSFont, codeFont: NSFont, listContext: inout ListContext) -> NSAttributedString? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        let originalLine = line
        
        // Headers (# ## ### #### ##### ######) - these break lists
        if let headerMatch = trimmedLine.range(of: #"^#{1,6}\s+"#, options: .regularExpression) {
            listContext.reset()
            let level = headerMatch.upperBound.utf16Offset(in: trimmedLine) - headerMatch.lowerBound.utf16Offset(in: trimmedLine) - 1
            let text = String(trimmedLine[headerMatch.upperBound...])
            return createHeading(text, level: level)
        }
        // Blockquotes (> text) - these break lists
        else if trimmedLine.hasPrefix("> ") {
            listContext.reset()
            let text = String(trimmedLine.dropFirst(2))
            return createBlockquote(text, baseFont: baseFont, codeFont: codeFont)
        }
        // Unordered lists with nested support
        else if let listMatch = trimmedLine.range(of: #"^(\s*)([-*+])\s+"#, options: .regularExpression) {
            let prefix = String(trimmedLine[..<listMatch.upperBound])
            let indentLevel = calculateIndentLevel(prefix)
            let text = String(trimmedLine[listMatch.upperBound...])
            listContext.updateWith(level: indentLevel, type: .unordered)
            return createUnorderedListItem(text, level: indentLevel, baseFont: baseFont, codeFont: codeFont)
        }
        // Ordered lists with nested support
        else if let numberMatch = trimmedLine.range(of: #"^(\s*)(\d+)\.\s+"#, options: .regularExpression) {
            let prefix = String(trimmedLine[..<numberMatch.upperBound])
            let indentLevel = calculateIndentLevel(prefix)
            let number = String(trimmedLine[numberMatch]).trimmingCharacters(in: .whitespaces).dropLast() // Remove the dot
            let text = String(trimmedLine[numberMatch.upperBound...])
            listContext.updateWith(level: indentLevel, type: .ordered)
            return createOrderedListItem(text, number: String(number), level: indentLevel, baseFont: baseFont, codeFont: codeFont)
        }
        // Task lists (- [x] or - [ ]) with nested support
        else if let taskMatch = trimmedLine.range(of: #"^(\s*)([-*+])\s*\[([ xX])\]\s+"#, options: .regularExpression) {
            let prefix = String(trimmedLine[..<taskMatch.upperBound])
            let indentLevel = calculateIndentLevel(prefix)
            let checkbox = String(trimmedLine[taskMatch])
            let isChecked = checkbox.contains("x") || checkbox.contains("X")
            let text = String(trimmedLine[taskMatch.upperBound...])
            listContext.updateWith(level: indentLevel, type: .task)
            return createTaskListItem(text, isChecked: isChecked, level: indentLevel, baseFont: baseFont, codeFont: codeFont)
        }
        // Definition lists (: definition)
        else if trimmedLine.hasPrefix(": ") {
            let text = String(trimmedLine.dropFirst(2))
            listContext.updateWith(level: 1, type: .definition)
            return createDefinition(text, baseFont: baseFont, codeFont: codeFont)
        }
        // List continuation - check if this is a continuation of a previous list
        else if isListContinuationWithContext(originalLine, listContext: listContext) {
            let indentLevel = listContext.currentLevel
            listContext.setContinuation()
            return createListContinuation(trimmedLine, level: indentLevel, baseFont: baseFont, codeFont: codeFont)
        }
        else {
            // Regular paragraph - this breaks lists unless it's clearly a continuation
            listContext.reset()
            return parseInlineMarkdown(trimmedLine, baseFont: baseFont, codeFont: codeFont)
        }
    }
    
    private func createHeading(_ text: String, level: Int) -> NSAttributedString {
        let fontSize: CGFloat
        switch level {
        case 1: fontSize = 24
        case 2: fontSize = 20
        case 3: fontSize = 18
        case 4: fontSize = 16
        case 5: fontSize = 14
        case 6: fontSize = 13
        default: fontSize = 14
        }
        
        let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
        let codeFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .regular)
        
        // Process inline markdown within heading
        let inlineProcessed = parseInlineMarkdown(text, baseFont: headingFont, codeFont: codeFont)
        
        // Create a mutable copy to modify attributes
        let result = NSMutableAttributedString(attributedString: inlineProcessed)
        
        // Apply heading formatting to the entire string
        result.enumerateAttributes(in: NSRange(location: 0, length: result.length), options: []) { attributes, range, _ in
            var newAttributes = attributes
            
            // Preserve bold/italic formatting but ensure heading font size
            if let font = attributes[.font] as? NSFont {
                if font.fontDescriptor.symbolicTraits.contains(.bold) {
                    newAttributes[.font] = NSFont.boldSystemFont(ofSize: fontSize)
                } else if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    newAttributes[.font] = NSFont.systemFont(ofSize: fontSize).withTraits(.italic)
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
    
    private func parseInlineMarkdown(_ text: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Use NSScanner for more efficient parsing
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            // Look for strikethrough (~~text~~)
            if scanner.scanString("~~") != nil {
                if let strikeText = scanUntilPattern(scanner, pattern: "~~") {
                    result.append(NSAttributedString(
                        string: strikeText,
                        attributes: [
                            .font: baseFont,
                            .strikethroughStyle: NSUnderlineStyle.single.rawValue
                        ]
                    ))
                } else {
                    result.append(NSAttributedString(string: "~~", attributes: [.font: baseFont]))
                }
            }
            // Look for bold (**text** or __text__)
            else if scanner.scanString("**") != nil {
                if let boldText = scanUntilPattern(scanner, pattern: "**") {
                    result.append(NSAttributedString(
                        string: boldText,
                        attributes: [.font: NSFont.boldSystemFont(ofSize: baseFont.pointSize)]
                    ))
                } else {
                    result.append(NSAttributedString(string: "**", attributes: [.font: baseFont]))
                }
            }
            else if scanner.scanString("__") != nil {
                if let boldText = scanUntilPattern(scanner, pattern: "__") {
                    result.append(NSAttributedString(
                        string: boldText,
                        attributes: [.font: NSFont.boldSystemFont(ofSize: baseFont.pointSize)]
                    ))
                } else {
                    result.append(NSAttributedString(string: "__", attributes: [.font: baseFont]))
                }
            }
            // Look for italic (*text* or _text_)
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
            else if scanner.scanString("_") != nil {
                if let italicText = scanUntilPattern(scanner, pattern: "_") {
                    let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                    result.append(NSAttributedString(
                        string: italicText,
                        attributes: [.font: italicFont]
                    ))
                } else {
                    result.append(NSAttributedString(string: "_", attributes: [.font: baseFont]))
                }
            }
            // Look for links ([text](url) or <url>)
            else if scanner.scanString("[") != nil {
                if let linkText = scanUntilPattern(scanner, pattern: "]"),
                   scanner.scanString("(") != nil,
                   let linkURL = scanUntilPattern(scanner, pattern: ")") {
                    result.append(NSAttributedString(
                        string: linkText,
                        attributes: [
                            .font: baseFont,
                            .foregroundColor: NSColor.linkColor,
                            .underlineStyle: NSUnderlineStyle.single.rawValue,
                            .link: linkURL
                        ]
                    ))
                } else {
                    result.append(NSAttributedString(string: "[", attributes: [.font: baseFont]))
                }
            }
            // Look for auto-links (<url>)
            else if scanner.scanString("<") != nil {
                if let urlText = scanUntilPattern(scanner, pattern: ">") {
                    if urlText.starts(with: "http") || urlText.contains("@") {
                        result.append(NSAttributedString(
                            string: urlText,
                            attributes: [
                                .font: baseFont,
                                .foregroundColor: NSColor.linkColor,
                                .underlineStyle: NSUnderlineStyle.single.rawValue,
                                .link: urlText
                            ]
                        ))
                    } else {
                        result.append(NSAttributedString(string: "<\(urlText)>", attributes: [.font: baseFont]))
                    }
                } else {
                    result.append(NSAttributedString(string: "<", attributes: [.font: baseFont]))
                }
            }
            // Look for images (![alt](src))
            else if scanner.scanString("!") != nil {
                if scanner.scanString("[") != nil,
                   let altText = scanUntilPattern(scanner, pattern: "]"),
                   scanner.scanString("(") != nil,
                   let _ = scanUntilPattern(scanner, pattern: ")") {
                    // For RTF, we'll represent images as [Image: alt text]
                    result.append(NSAttributedString(
                        string: "[Image: \(altText)]",
                        attributes: [
                            .font: baseFont.withTraits(.italic),
                            .foregroundColor: NSColor.secondaryLabelColor
                        ]
                    ))
                } else {
                    result.append(NSAttributedString(string: "!", attributes: [.font: baseFont]))
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
            else if let regularText = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "~*_[<`!")) {
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
    
    // MARK: - Helper Methods for New Markdown Features
    
    private func createBlockquote(_ text: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: "▌ ")
        result.addAttributes([
            .foregroundColor: NSColor.quaternaryLabelColor,
            .font: baseFont
        ], range: NSRange(location: 0, length: 2))
        
        let content = parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont)
        result.append(content)
        
        // Add left margin/padding effect
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 20
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    private func createUnorderedListItem(_ text: String, level: Int, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        // Parse the content first
        let content = parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont)
        let result = NSMutableAttributedString(attributedString: content)
        
        // Create proper RTF list using NSTextList with level-appropriate markers
        let markerFormat: NSTextList.MarkerFormat
        switch level {
        case 0:
            markerFormat = .disc
        case 1:
            markerFormat = .circle
        case 2:
            markerFormat = .square
        default:
            markerFormat = .disc
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
    
    private func createOrderedListItem(_ text: String, number: String, level: Int, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        // Parse the content first
        let content = parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont)
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
    
    private func createTaskListItem(_ text: String, isChecked: Bool, level: Int, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let checkbox = isChecked ? "☑ " : "☐ "
        
        let result = NSMutableAttributedString(string: checkbox)
        result.addAttributes([.font: baseFont], range: NSRange(location: 0, length: result.length))
        
        let content = parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont)
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
    
    private func createDefinition(_ text: String, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: "    ")
        result.addAttributes([.font: baseFont], range: NSRange(location: 0, length: 4))
        
        let content = parseInlineMarkdown(text, baseFont: baseFont, codeFont: codeFont)
        result.append(content)
        
        return result
    }
    
    private func createHorizontalRule() -> NSAttributedString {
        let rule = String(repeating: "─", count: 50)
        return NSAttributedString(
            string: rule,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.separatorColor
            ]
        )
    }
    
    private func isHorizontalRule(_ line: String) -> Bool {
        let cleanLine = line.trimmingCharacters(in: .whitespaces)
        return (cleanLine.allSatisfy { $0 == "-" } && cleanLine.count >= 3) ||
               (cleanLine.allSatisfy { $0 == "*" } && cleanLine.count >= 3) ||
               (cleanLine.allSatisfy { $0 == "_" } && cleanLine.count >= 3)
    }
    
    private func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // A table row must contain at least one pipe character
        // and should have at least 2 cells (indicated by having content around the pipe)
        guard trimmed.contains("|") else { return false }
        
        // Split by pipe and check if we have at least 2 non-empty cells
        let cells = trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        let nonEmptyCells = cells.filter { !$0.isEmpty }
        
        return nonEmptyCells.count >= 2
    }
    
    private func parseTableStructure(lines: [String], startIndex: Int) -> (tableData: RTFTableGenerator.TableData, endIndex: Int) {
        var tableLines: [String] = []
        var currentIndex = startIndex
        
        // Collect all consecutive table rows
        while currentIndex < lines.count {
            let line = lines[currentIndex].trimmingCharacters(in: .whitespaces)
            if isTableRow(line) {
                tableLines.append(line)
                currentIndex += 1
            } else {
                break
            }
        }
        
        var headerRow: [String] = []
        var separatorFound = false
        var dataRows: [[String]] = []
        
        // Process each line
        for (index, line) in tableLines.enumerated() {
            let cells = parseTableCells(line)
            
            // Check if this is a separator row (---|---|---)
            if isSeparatorRow(line) {
                separatorFound = true
                continue
            }
            
            if !separatorFound && index == 0 {
                // First row before separator is header
                headerRow = cells
            } else if separatorFound || headerRow.isEmpty {
                // Data rows (either we found a separator or no header detected)
                dataRows.append(cells)
            }
        }
        
        // If no separator was found, treat the first row as data
        if !separatorFound && !headerRow.isEmpty {
            dataRows.insert(headerRow, at: 0)
            headerRow = []
        }
        
        let tableData = RTFTableGenerator.TableData(
            headerRow: headerRow,
            dataRows: dataRows,
            hasHeader: !headerRow.isEmpty
        )
        
        return (tableData, currentIndex)
    }

    // Keep the old parseTable function for backward compatibility or fallback
    private func parseTable(lines: [String], startIndex: Int) -> (attributedString: NSAttributedString, endIndex: Int) {
        var tableLines: [String] = []
        var currentIndex = startIndex
        
        // Collect all consecutive table rows
        while currentIndex < lines.count {
            let line = lines[currentIndex].trimmingCharacters(in: .whitespaces)
            if isTableRow(line) {
                tableLines.append(line)
                currentIndex += 1
            } else {
                break
            }
        }
        
        // Parse the table structure
        let result = NSMutableAttributedString()
        let baseFont = NSFont.systemFont(ofSize: 13)
        let headerFont = NSFont.boldSystemFont(ofSize: 13)
        let codeFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        
        var headerRow: [String] = []
        var separatorFound = false
        var dataRows: [[String]] = []
        
        // Process each line
        for (index, line) in tableLines.enumerated() {
            let cells = parseTableCells(line)
            
            // Check if this is a separator row (---|---|---)
            if isSeparatorRow(line) {
                separatorFound = true
                continue
            }
            
            if !separatorFound && index == 0 {
                // First row before separator is header
                headerRow = cells
            } else if separatorFound || headerRow.isEmpty {
                // Data rows (either we found a separator or no header detected)
                dataRows.append(cells)
            }
        }
        
        // If no separator was found, treat the first row as data
        if !separatorFound && !headerRow.isEmpty {
            dataRows.insert(headerRow, at: 0)
            headerRow = []
        }
        
        // Create table with proper RTF formatting
        let tableResult = createFormattedTable(
            headerRow: headerRow,
            dataRows: dataRows,
            baseFont: baseFont,
            headerFont: headerFont,
            codeFont: codeFont
        )
        
        result.append(tableResult)
        
        return (result, currentIndex)
    }
    
    private func parseTableCells(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var cells = trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Remove empty cells at the beginning and end (from leading/trailing pipes)
        if cells.first?.isEmpty == true {
            cells.removeFirst()
        }
        if cells.last?.isEmpty == true {
            cells.removeLast()
        }
        
        return cells
    }
    
    private func isSeparatorRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let cleaned = trimmed.replacingOccurrences(of: "|", with: "")
                           .replacingOccurrences(of: "-", with: "")
                           .replacingOccurrences(of: ":", with: "")
                           .replacingOccurrences(of: " ", with: "")
        return cleaned.isEmpty && trimmed.contains("-")
    }
    
    private func createFormattedTable(
        headerRow: [String],
        dataRows: [[String]],
        baseFont: NSFont,
        headerFont: NSFont,
        codeFont: NSFont
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Determine the maximum number of columns
        let maxColumns = max(headerRow.count, dataRows.map { $0.count }.max() ?? 0)
        
        // Add header row if present
        if !headerRow.isEmpty {
            let headerContent = createTableRowContent(
                cells: headerRow,
                maxColumns: maxColumns,
                font: headerFont,
                codeFont: codeFont
            )
            result.append(headerContent)
            result.append(NSAttributedString(string: "\n"))
            
            // Add separator line after header
            let separatorLine = createTableSeparatorLine(maxColumns: maxColumns)
            result.append(separatorLine)
            result.append(NSAttributedString(string: "\n"))
        }
        
        // Add data rows
        for (index, row) in dataRows.enumerated() {
            let rowContent = createTableRowContent(
                cells: row,
                maxColumns: maxColumns,
                font: baseFont,
                codeFont: codeFont
            )
            result.append(rowContent)
            
            // Add newline between rows (but not after the last row)
            if index < dataRows.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        
        return result
    }
    
    private func createTableRowContent(
        cells: [String],
        maxColumns: Int,
        font: NSFont,
        codeFont: NSFont
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for columnIndex in 0..<maxColumns {
            let cellContent = columnIndex < cells.count ? cells[columnIndex] : ""
            
            // Parse inline markdown within the cell
            let parsedContent = parseInlineMarkdown(cellContent, baseFont: font, codeFont: codeFont)
            
            // Create a mutable copy to ensure consistent font
            let mutableContent = NSMutableAttributedString(attributedString: parsedContent)
            
            // Ensure the cell content uses the correct base font
            mutableContent.enumerateAttributes(in: NSRange(location: 0, length: mutableContent.length), options: []) { attributes, range, _ in
                var newAttributes = attributes
                if let currentFont = attributes[.font] as? NSFont {
                    // Preserve formatting but ensure consistent size
                    if currentFont.fontDescriptor.symbolicTraits.contains(.bold) {
                        newAttributes[.font] = NSFont.boldSystemFont(ofSize: font.pointSize)
                    } else if currentFont.fontDescriptor.symbolicTraits.contains(.italic) {
                        newAttributes[.font] = NSFont.systemFont(ofSize: font.pointSize).withTraits(.italic)
                    } else {
                        newAttributes[.font] = font
                    }
                }
                mutableContent.setAttributes(newAttributes, range: range)
            }
            
            result.append(mutableContent)
            
            // Add column separator (except for the last column)
            if columnIndex < maxColumns - 1 {
                result.append(NSAttributedString(
                    string: " │ ",
                    attributes: [
                        .font: font,
                        .foregroundColor: NSColor.separatorColor
                    ]
                ))
            }
        }
        
        return result
    }
    
    private func createTableSeparatorLine(maxColumns: Int) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseFont = NSFont.systemFont(ofSize: 13)
        
        for columnIndex in 0..<maxColumns {
            // Create a line of dashes for each column
            let dashLine = String(repeating: "─", count: 12) // Fixed width for consistency
            result.append(NSAttributedString(
                string: dashLine,
                attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.separatorColor
                ]
            ))
            
            // Add column separator (except for the last column)
            if columnIndex < maxColumns - 1 {
                result.append(NSAttributedString(
                    string: "─┼─",
                    attributes: [
                        .font: baseFont,
                        .foregroundColor: NSColor.separatorColor
                    ]
                ))
            }
        }
        
        return result
    }
    
    // MARK: - List Processing Helpers
    
    private func calculateIndentLevel(_ prefix: String) -> Int {
        // Count leading whitespace - support both spaces and tabs
        let spaces = prefix.filter { $0 == " " }.count
        let tabs = prefix.filter { $0 == "\t" }.count
        
        // More flexible indentation handling for real-world content
        // Many people use 2, 3, or 6 spaces for sublists
        // Try to detect the pattern and be more flexible
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
    
    private func getListBulletStyle(for level: Int) -> String {
        // Use different bullet styles for different nesting levels
        let bullets = ["• ", "◦ ", "▪ ", "▫ "]
        return bullets[level % bullets.count]
    }
    
    private func isListContinuationWithContext(_ line: String, listContext: ListContext) -> Bool {
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
    
    private func isNewListItem(_ trimmed: String) -> Bool {
        // Check all the patterns that would indicate a new list item
        let isUnordered = trimmed.range(of: #"^([-*+])\s"#, options: .regularExpression) != nil
        let isOrdered = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
        let isTask = trimmed.range(of: #"^([-*+])\s*\[([ xX])\]\s"#, options: .regularExpression) != nil
        let isDefinition = trimmed.hasPrefix(": ")
        
        return isUnordered || isOrdered || isTask || isDefinition
    }
    
    private func createListContinuation(_ text: String, level: Int, baseFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let content = parseInlineMarkdown(text.trimmingCharacters(in: .whitespaces), baseFont: baseFont, codeFont: codeFont)
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
    
    private func isListItem(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Check for unordered list
        if trimmed.range(of: #"^(\s*)([-*+])\s+"#, options: .regularExpression) != nil {
            return true
        }
        
        // Check for ordered list
        if trimmed.range(of: #"^(\s*)(\d+)\.\s+"#, options: .regularExpression) != nil {
            return true
        }
        
        // Check for task list
        if trimmed.range(of: #"^(\s*)([-*+])\s*\[([ xX])\]\s+"#, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    private func getListLevel(_ line: String) -> Int {
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

// MARK: - Extensions

extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
