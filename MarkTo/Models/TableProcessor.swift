import Foundation
import AppKit

/// Parses pipe-delimited Markdown tables and renders them as portable attributed
/// text. The textual separators survive RTF serialization in TextEdit, Pages,
/// Microsoft Word, and clipboard consumers that do not support NSTextTable.
final class TableProcessor {
    struct TableParsingResult {
        let content: NSAttributedString
        let endIndex: Int
    }

    private struct TableData {
        let headerRow: [String]
        let dataRows: [[String]]
        let hasHeader: Bool

        var maxColumns: Int {
            max(headerRow.count, dataRows.map(\.count).max() ?? 0)
        }
    }

    private let inlineProcessor: InlineProcessor

    init(inlineProcessor: InlineProcessor) {
        self.inlineProcessor = inlineProcessor
    }

    /// A table row must be explicitly pipe-delimited. Requiring a leading or
    /// trailing pipe avoids converting ordinary prose such as `A | B`.
    func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") || trimmed.hasSuffix("|") else { return false }
        return unescapedPipeCount(in: trimmed) >= 2
    }

    func parseTable(
        lines: [String],
        startIndex: Int,
        context: ParsingContext
    ) -> TableParsingResult {
        var tableLines: [String] = []
        var currentIndex = startIndex

        while currentIndex < lines.count, isTableRow(lines[currentIndex]) {
            tableLines.append(lines[currentIndex])
            currentIndex += 1
        }

        let data = parseTableData(tableLines)
        return TableParsingResult(
            content: renderTable(data, context: context),
            endIndex: currentIndex
        )
    }

    internal func isHeaderSeparator(_ line: String) -> Bool {
        guard isTableRow(line) else { return false }
        let cells = parseTableRow(line)
        guard !cells.isEmpty else { return false }

        return cells.allSatisfy { cell in
            let marker = cell.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            return !marker.isEmpty && marker.allSatisfy { $0 == "-" }
        }
    }

    private func parseTableData(_ lines: [String]) -> TableData {
        guard !lines.isEmpty else {
            return TableData(headerRow: [], dataRows: [], hasHeader: false)
        }

        let hasHeader = lines.count > 1 && isHeaderSeparator(lines[1])
        if hasHeader {
            return TableData(
                headerRow: parseTableRow(lines[0]),
                dataRows: lines.dropFirst(2).map(parseTableRow),
                hasHeader: true
            )
        }

        return TableData(
            headerRow: [],
            dataRows: lines.map(parseTableRow),
            hasHeader: false
        )
    }

    private func parseTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }

        var cells: [String] = []
        var current = ""
        var isEscaped = false

        for character in trimmed {
            if isEscaped {
                current.append(character)
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }

        if isEscaped { current.append("\\") }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }
    private func renderTable(_ table: TableData, context: ParsingContext) -> NSAttributedString {
        guard table.maxColumns > 0 else { return NSAttributedString() }

        let header = table.hasHeader ? renderCells(table.headerRow, context: context, isHeader: true) : []
        let rows = table.dataRows.map { renderCells($0, context: context, isHeader: false) }
        let allRows = (table.hasHeader ? [header] : []) + rows

        let columnWidths = (0..<table.maxColumns).map { column in
            max(
                3,
                allRows.compactMap { row in
                    column < row.count ? row[column].string.count : nil
                }.max() ?? 0
            )
        }

        let result = NSMutableAttributedString()
        if table.hasHeader {
            appendRow(header, columnWidths: columnWidths, to: result, context: context)
            appendSeparator(columnWidths: columnWidths, to: result, context: context)
        }

        for row in rows {
            appendRow(row, columnWidths: columnWidths, to: result, context: context)
        }

        return result
    }

    private func renderCells(
        _ cells: [String],
        context: ParsingContext,
        isHeader: Bool
    ) -> [NSAttributedString] {
        cells.map { cell in
            let rendered = NSMutableAttributedString(
                attributedString: inlineProcessor.processInlineMarkdown(
                    cell,
                    baseFont: context.baseFont,
                    codeFont: context.codeFont
                )
            )

            if isHeader, rendered.length > 0 {
                rendered.enumerateAttribute(
                    .font,
                    in: NSRange(location: 0, length: rendered.length)
                ) { value, range, _ in
                    guard let font = value as? NSFont else { return }
                    let traits = font.fontDescriptor.symbolicTraits.union(.bold)
                    let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
                    let boldFont = NSFont(descriptor: descriptor, size: font.pointSize)
                        ?? NSFont.boldSystemFont(ofSize: font.pointSize)
                    rendered.addAttribute(.font, value: boldFont, range: range)
                }
            }

            return rendered
        }
    }

    private func appendRow(
        _ cells: [NSAttributedString],
        columnWidths: [Int],
        to result: NSMutableAttributedString,
        context: ParsingContext
    ) {
        for column in columnWidths.indices {
            let cell = column < cells.count ? cells[column] : NSAttributedString()
            result.append(cell)

            let paddingCount = max(0, columnWidths[column] - cell.string.count)
            if paddingCount > 0 {
                result.append(NSAttributedString(
                    string: String(repeating: " ", count: paddingCount),
                    attributes: [.font: context.baseFont]
                ))
            }

            if column < columnWidths.count - 1 {
                result.append(NSAttributedString(
                    string: " │ ",
                    attributes: [.font: context.baseFont]
                ))
            }
        }
        result.append(NSAttributedString(string: "\n"))
    }

    private func appendSeparator(
        columnWidths: [Int],
        to result: NSMutableAttributedString,
        context: ParsingContext
    ) {
        let separator = columnWidths
            .map { String(repeating: "─", count: $0) }
            .joined(separator: "─┼─")
        result.append(NSAttributedString(
            string: separator + "\n",
            attributes: [
                .font: context.baseFont,
                .foregroundColor: NSColor.separatorColor
            ]
        ))
    }

    private func unescapedPipeCount(in line: String) -> Int {
        var count = 0
        var isEscaped = false

        for character in line {
            if isEscaped {
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == "|" {
                count += 1
            }
        }

        return count
    }
}
