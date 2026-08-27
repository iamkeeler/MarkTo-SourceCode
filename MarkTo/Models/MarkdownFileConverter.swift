import Foundation
import AppKit

enum MarkdownFileConversionError: Error, LocalizedError {
    case unsupportedFile(URL)
    case unreadableFile(URL)
    case conversionFailed(MarkdownConversionError)
    case rtfSerializationFailed
    case writeFailed(URL, Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile(let url):
            return "\(url.lastPathComponent) is not a Markdown file"
        case .unreadableFile(let url):
            return "Could not read \(url.lastPathComponent) as UTF-8 Markdown"
        case .conversionFailed(let error):
            return error.localizedDescription
        case .rtfSerializationFailed:
            return "Could not generate RTF data"
        case .writeFailed(let url, _):
            return "Could not write \(url.lastPathComponent)"
        }
    }
}

struct MarkdownFileConversionResult: @unchecked Sendable {
    let sourceURL: URL
    let outputURL: URL
    let markdown: String
}

/// Converts a Markdown document to a sibling RTF file without overwriting an existing export.
final class MarkdownFileConverter: @unchecked Sendable {
    private static let supportedExtensions: Set<String> = ["md", "markdown"]

    private let converter: MarkdownConverter
    private let fileManager: FileManager

    init(
        formatting: FormattingSnapshot = .defaults,
        fileManager: FileManager = .default
    ) {
        converter = MarkdownConverter(formatting: formatting)
        self.fileManager = fileManager
    }

    static func supports(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    func convertFile(at sourceURL: URL) -> Result<MarkdownFileConversionResult, MarkdownFileConversionError> {
        guard Self.supports(sourceURL) else {
            return .failure(.unsupportedFile(sourceURL))
        }

        let hasSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let markdown = try? String(contentsOf: sourceURL, encoding: .utf8) else {
            return .failure(.unreadableFile(sourceURL))
        }

        let attributedString: NSAttributedString
        switch converter.convertToRTF(markdown) {
        case .success(let value):
            attributedString = value
        case .failure(let error):
            return .failure(.conversionFailed(error))
        }

        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            return .failure(.rtfSerializationFailed)
        }

        let outputURL = nextAvailableOutputURL(for: sourceURL)
        do {
            try rtfData.write(to: outputURL, options: .withoutOverwriting)
            return .success(
                MarkdownFileConversionResult(
                    sourceURL: sourceURL,
                    outputURL: outputURL,
                    markdown: markdown
                )
            )
        } catch {
            return .failure(.writeFailed(outputURL, error))
        }
    }

    private func nextAvailableOutputURL(for sourceURL: URL) -> URL {
        let directoryURL = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var candidate = directoryURL.appendingPathComponent(baseName).appendingPathExtension("rtf")
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL
                .appendingPathComponent("\(baseName) \(suffix)")
                .appendingPathExtension("rtf")
            suffix += 1
        }

        return candidate
    }
}
