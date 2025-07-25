import Foundation
import AppKit

// MARK: - Table Processor
/// Handles markdown table parsing and RTF table generation
class TableProcessor {
    private let inlineProcessor: InlineProcessor
    
    // Table parsing result
    struct TableParsingResult {
        let content: NSAttributedString
        let endIndex: Int
    }
    
    // Table data structure
    struct TableData {
        let headerRow: [String]
        let dataRows: [[String]]
        let hasHeader: Bool
        
        var maxColumns: Int {
            max(headerRow.count, dataRows.map { $0.count }.max() ?? 0)
        }
    }
    
    init(inlineProcessor: InlineProcessor) {
        self.inlineProcessor = inlineProcessor
    }
    
    // MARK: - Public Methods
    
    /// Check if line represents a table row
    func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Must contain at least one pipe character
        guard trimmed.contains("|") else { return false }
        
        // Simple check: if it has pipes and isn't obviously something else
        return true
    }
    
    /// Parse complete table structure starting from given index
    func parseTable(lines: [String], startIndex: Int, context: ParsingContext) -> TableParsingResult {
        var tableLines: [String] = []
        var currentIndex = startIndex
        
        // Collect consecutive table lines
        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if isTableRow(trimmed) {
                tableLines.append(line)
                currentIndex += 1
            } else {
                break
            }
        }
        
        // Parse the collected table lines
        let tableData = parseTableData(tableLines)
        let rtfTable = generateRTFTable(from: tableData, context: context)
        
        return TableParsingResult(content: rtfTable, endIndex: currentIndex)
    }
    
    // MARK: - Private Table Processing
    
    private func parseTableData(_ lines: [String]) -> TableData {
        guard !lines.isEmpty else {
            return TableData(headerRow: [], dataRows: [], hasHeader: false)
        }
        
        var processedLines: [String] = []
        var hasHeader = false
        
        // Process lines and detect header separator
        for (_, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if this is a header separator line (contains only |, -, :, and spaces)
            if isHeaderSeparator(trimmed) {
                hasHeader = true
                continue // Skip separator line
            }
            
            processedLines.append(trimmed)
        }
        
        guard !processedLines.isEmpty else {
            return TableData(headerRow: [], dataRows: [], hasHeader: false)
        }
        
        if hasHeader && processedLines.count > 1 {
            let headerRow = parseTableRow(processedLines[0])
            let dataRows = Array(processedLines[1...]).map { parseTableRow($0) }
            return TableData(headerRow: headerRow, dataRows: dataRows, hasHeader: true)
        } else {
            let dataRows = processedLines.map { parseTableRow($0) }
            return TableData(headerRow: [], dataRows: dataRows, hasHeader: false)
        }
    }
    
    private func parseTableRow(_ line: String) -> [String] {
        var cells: [String] = []
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Remove leading and trailing pipes
        var workingLine = trimmed
        if workingLine.hasPrefix("|") {
            workingLine = String(workingLine.dropFirst())
        }
        if workingLine.hasSuffix("|") {
            workingLine = String(workingLine.dropLast())
        }
        
        // Split by pipes and clean up
        let rawCells = workingLine.components(separatedBy: "|")
        for cell in rawCells {
            cells.append(cell.trimmingCharacters(in: .whitespaces))
        }
        
        return cells
    }
    
    private func isHeaderSeparator(_ line: String) -> Bool {
        let validChars = CharacterSet(charactersIn: "|-: ")
        let lineCharSet = CharacterSet(charactersIn: line)
        
        // Must contain at least one dash and be composed only of valid characters
        return line.contains("-") && validChars.isSuperset(of: lineCharSet)
    }
    
    // MARK: - RTF Table Generation
    
    private func generateRTFTable(from tableData: TableData, context: ParsingContext) -> NSAttributedString {
        // Try HTML table approach first - many apps recognize HTML table structure better than RTF
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
            // HTML parsing failed, fall back to plain text table
            return generatePlainTextTable(from: tableData, context: context)
        }
    }
    
    /*
    // TODO: Fix NSTextTable API usage - currently has compilation errors
    private func generateNativeRTFTable(from tableData: TableData, context: ParsingContext) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Create the table using NSTextTable (proper RTF table structure)
        let textTable = NSTextTable()
        textTable.numberOfColumns = tableData.maxColumns
        textTable.layoutAlgorithm = .automaticLayout
        textTable.collapsesBorders = true
        
        // Configure table appearance
        textTable.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.1)
        
        // Set column widths to be equal
        let columnWidth = 100.0 / Double(tableData.maxColumns)
        for i in 0..<tableData.maxColumns {
            textTable.setWidth(columnWidth, type: .percentageValueType, for: NSTextTableBlock.horizontalAlignment.natural)
        }
        
        // Add header row if present
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            let headerRow = createTableRow(
                cells: tableData.headerRow,
                table: textTable,
                isHeader: true,
                maxColumns: tableData.maxColumns,
                context: context
            )
            result.append(headerRow)
        }
        
        // Add data rows
        for row in tableData.dataRows {
            let dataRow = createTableRow(
                cells: row,
                table: textTable,
                isHeader: false,
                maxColumns: tableData.maxColumns,
                context: context
            )
            result.append(dataRow)
        }
        
        return result
    }
    */
    /*
    // TODO: Fix NSTextTable API usage - part of native RTF table generation
    private func createTableRow(
        cells: [String],
        table: NSTextTable,
        isHeader: Bool,
        maxColumns: Int,
        context: ParsingContext
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for columnIndex in 0..<maxColumns {
            let cellContent = columnIndex < cells.count ? cells[columnIndex] : ""
            
            // Create table cell block
            let cellBlock = NSTextTableBlock(table: table, startingRow: 0, rowSpan: 1, startingColumn: columnIndex, columnSpan: 1)
            
            // Configure cell appearance
            cellBlock.setBorderColor(NSColor.separatorColor, for: .borderAll)
            cellBlock.setBorderWidth(0.5, for: .borderAll)
            cellBlock.setContentWidth(100.0, type: .percentageValueType, for: .width)
            
            // Set cell background
            if isHeader {
                cellBlock.setBackgroundColor(NSColor.controlBackgroundColor.withAlphaComponent(0.3), for: .cell)
            } else {
                cellBlock.setBackgroundColor(NSColor.controlBackgroundColor.withAlphaComponent(0.05), for: .cell)
            }
            
            // Set cell padding
            cellBlock.setContentWidth(4.0, type: .absoluteValueType, for: .paddingLeft)
            cellBlock.setContentWidth(4.0, type: .absoluteValueType, for: .paddingRight)
            cellBlock.setContentWidth(2.0, type: .absoluteValueType, for: .paddingTop)
            cellBlock.setContentWidth(2.0, type: .absoluteValueType, for: .paddingBottom)
            
            // Create paragraph style with table block
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.textBlocks = [cellBlock]
            
            // Set text alignment
            paragraphStyle.alignment = .natural
            
            // Create attributed string for cell content
            let font = isHeader ? NSFont.boldSystemFont(ofSize: 13) : NSFont.systemFont(ofSize: 13)
            let cellAttributedString = NSAttributedString(
                string: cellContent,
                attributes: [
                    .font: font,
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: NSColor.textColor
                ]
            )
            
            result.append(cellAttributedString)
            
            // Add paragraph break after each cell
            result.append(NSAttributedString(string: "\n"))
        }
        
        return result
    }
    */
    
    private func generateHTMLTable(from tableData: TableData) -> String {
        var html = "<table border='1' cellpadding='4' cellspacing='0' style='border-collapse: collapse;'>"
        
        // Header row
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            html += "<tr>"
            for cell in tableData.headerRow {
                let escapedCell = escapeHTMLContent(cell)
                html += "<th style='font-weight: bold; background-color: #f0f0f0;'>\(escapedCell)</th>"
            }
            html += "</tr>"
        }
        
        // Data rows
        for row in tableData.dataRows {
            html += "<tr>"
            for cell in row {
                let escapedCell = escapeHTMLContent(cell)
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
    
    private func generatePlainTextTable(from tableData: TableData, context: ParsingContext) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Calculate column widths for alignment
        var columnWidths: [Int] = []
        for columnIndex in 0..<tableData.maxColumns {
            var maxWidth = 0
            
            // Check header width
            if tableData.hasHeader && columnIndex < tableData.headerRow.count {
                maxWidth = max(maxWidth, tableData.headerRow[columnIndex].count)
            }
            
            // Check data rows width
            for row in tableData.dataRows {
                if columnIndex < row.count {
                    maxWidth = max(maxWidth, row[columnIndex].count)
                }
            }
            
            columnWidths.append(max(maxWidth, 3)) // Minimum width of 3
        }
        
        // Generate header row if present
        if tableData.hasHeader && !tableData.headerRow.isEmpty {
            let headerString = NSMutableAttributedString()
            
            for (index, cell) in tableData.headerRow.enumerated() {
                let paddedCell = cell.padding(toLength: columnWidths[index], withPad: " ", startingAt: 0)
                let cellString = NSAttributedString(string: paddedCell, attributes: [.font: NSFont.boldSystemFont(ofSize: context.baseFont.pointSize)])
                headerString.append(cellString)
                
                if index < tableData.headerRow.count - 1 {
                    headerString.append(NSAttributedString(string: " │ "))
                }
            }
            result.append(headerString)
            result.append(NSAttributedString(string: "\n"))
            
            // Add separator line
            var separatorLine = ""
            for (index, width) in columnWidths.enumerated() {
                separatorLine += String(repeating: "─", count: width)
                if index < columnWidths.count - 1 {
                    separatorLine += "─┼─"
                }
            }
            result.append(NSAttributedString(string: separatorLine + "\n"))
        }
        
        // Generate data rows
        for row in tableData.dataRows {
            let rowString = NSMutableAttributedString()
            
            for columnIndex in 0..<tableData.maxColumns {
                let cellContent = columnIndex < row.count ? row[columnIndex] : ""
                let paddedCell = cellContent.padding(toLength: columnWidths[columnIndex], withPad: " ", startingAt: 0)
                let cellString = NSAttributedString(string: paddedCell, attributes: [.font: context.baseFont])
                rowString.append(cellString)
                
                if columnIndex < tableData.maxColumns - 1 {
                    rowString.append(NSAttributedString(string: " │ "))
                }
            }
            result.append(rowString)
            result.append(NSAttributedString(string: "\n"))
        }
        
        return result
    }
    
    private func escapeHTMLContent(_ text: String) -> String {
        return text.replacingOccurrences(of: "&", with: "&amp;")
                  .replacingOccurrences(of: "<", with: "&lt;")
                  .replacingOccurrences(of: ">", with: "&gt;")
                  .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
