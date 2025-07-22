import Foundation
import AppKit

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
                maxColumns: tableData.maxColumns
            )
            result.append(headerRow)
        }
        
        // Add data rows
        for row in tableData.dataRows {
            let dataRow = createTableRow(
                cells: row,
                table: textTable,
                isHeader: false,
                maxColumns: tableData.maxColumns
            )
            result.append(dataRow)
        }
        
        return result
    }
    
    private static func createTableRow(
        cells: [String],
        table: NSTextTable,
        isHeader: Bool,
        maxColumns: Int
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
}

// MARK: - RTF Table Parser Extension
extension MarkdownConverter {
    
    // Parse table structure for RTF generation
    func parseTableStructure(lines: [String], startIndex: Int) -> (tableData: RTFTableGenerator.TableData, endIndex: Int) {
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
}
