import Foundation
import AppKit

/// Class responsible for converting NSAttributedString (RTF) back to Markdown syntax.
class RTFToMarkdownConverter {

    enum MarkdownStyle {
        case bold
        case italic
        case inlineCode
    }

    /// Converts an NSAttributedString to a Markdown formatted string.
    func convertToMarkdown(_ attributedString: NSAttributedString) -> String {
        var markdownText = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, stop in
            let textRun = (attributedString.string as NSString).substring(with: range)
            guard !textRun.isEmpty else { return }

            // Check for list patterns or headers in the text string itself?
            // (Wait, since it's just plain text we only need to extract traits from attributes)

            var appliedStyles = [MarkdownStyle]()

            if let font = attributes[.font] as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits

                if traits.contains(.bold) {
                    appliedStyles.append(.bold)
                }
                if traits.contains(.italic) {
                    appliedStyles.append(.italic)
                }
                if font.fontDescriptor.fontAttributes[.family] as? String == "Menlo" ||
                   font.fontDescriptor.fontAttributes[.family] as? String == "Monaco" ||
                   font.fontDescriptor.fontAttributes[.family] as? String == "Courier" ||
                   traits.contains(.monoSpace) {
                    appliedStyles.append(.inlineCode)
                }
            }

            // Note: If text run contains newlines, we need to wrap each line segment,
            // or just wrap the whole thing if it doesn't cross block boundaries.
            // For simplicity, we'll process the text and wrap it.

            var processedText = escapeMarkdown(textRun)

            // For lists and headings, if we detect them via paragraph style or something similar,
            // but standard pasteboard might just preserve bullet characters instead of actual list attributes.
            // So textRun might already contain "• " or tab indentations.

            // Apply wrappers
            if appliedStyles.contains(.inlineCode) {
                processedText = "`\(processedText)`"
            }

            // bold and italic might surround spaces, which is bad markdown.
            // e.g. "**hello **" should be "**hello** "
            processedText = applyWrapping(text: processedText, prefix: "**", suffix: "**", if: appliedStyles.contains(.bold))
            processedText = applyWrapping(text: processedText, prefix: "*", suffix: "*", if: appliedStyles.contains(.italic))

            markdownText += processedText
        }

        return cleanUpMarkdown(markdownText)
    }

    private func applyWrapping(text: String, prefix: String, suffix: String, `if` condition: Bool) -> String {
        guard condition else { return text }

        // Handle whitespace at the edges to ensure valid markdown
        // e.g. " hello " -> " **hello** "
        var startSpaces = ""
        var endSpaces = ""
        var coreText = text

        while coreText.hasPrefix(" ") || coreText.hasPrefix("\n") {
            startSpaces += String(coreText.removeFirst())
        }
        while coreText.hasSuffix(" ") || coreText.hasSuffix("\n") {
            endSpaces = String(coreText.removeLast()) + endSpaces
        }

        if coreText.isEmpty {
            return text // if it was only spaces, don't wrap
        }

        return startSpaces + prefix + coreText + suffix + endSpaces
    }

    /// Escapes literal markdown characters so they aren't parsed as formatting later.
    private func escapeMarkdown(_ text: String) -> String {
        var escaped = text
        let charactersToEscape = ["*", "_", "`", "[", "]", "#"]

        for char in charactersToEscape {
            // Only escape if the character is not already escaped.
            // This is a naive replacement, it might double-escape if we aren't careful,
            // but assuming raw RTF text, there are no existing escape characters acting as escapes.
            escaped = escaped.replacingOccurrences(of: char, with: "\\\(char)")
        }
        return escaped
    }

    private func cleanUpMarkdown(_ text: String) -> String {
        // Fix any overlapping boundaries or double spaces created by the wrapper logic
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: "****", with: "")
        cleaned = cleaned.replacingOccurrences(of: "** **", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "* *", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "``", with: "")
        return cleaned
    }
}
