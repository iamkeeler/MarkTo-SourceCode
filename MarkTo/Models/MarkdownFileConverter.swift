import Foundation
import AppKit

enum MarkdownFileConversionError: Error, LocalizedError {
    case unsupportedFile(URL)
    case unreadableFile(URL)
    case fileTooLarge(URL)
    case conversionFailed(MarkdownConversionError)
    case rtfSerializationFailed
    case writeFailed(URL, Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile(let url):
            return "\(url.lastPathComponent) is not a Markdown file"
        case .unreadableFile(let url):
            return "Could not read \(url.lastPathComponent) as UTF-8 Markdown"
        case .fileTooLarge(let url):
            return "\(url.lastPathComponent) is too large to convert"
        case .conversionFailed(let error):
            return error.localizedDescription
        case .rtfSerializationFailed:
            return "Could not generate RTF data"
        case .writeFailed(let url, let error):
            return "Could not write \(url.lastPathComponent): \(error.localizedDescription)"
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

    /// Upper bound for files read into memory in one go.
    static let maxFileSize = 8 * 1024 * 1024

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

        let fileSize = (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard fileSize <= Self.maxFileSize else {
            return .failure(.fileTooLarge(sourceURL))
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
        switch converter.convertToAttributedString(markdown) {
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

        // Retry with a fresh sibling name if another process created the file
        // between our name check and the write (TOCTOU on .withoutOverwriting).
        var suffix = 2
        for _ in 0..<1000 {
            let outputURL = nextAvailableOutputURL(for: sourceURL, startingAt: suffix)
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
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain,
                   nsError.code == NSFileWriteFileExistsError {
                    suffix += 1
                    continue
                }
                return .failure(.writeFailed(outputURL, error))
            }
        }
        return .failure(.writeFailed(sourceURL, CocoaError(.fileWriteUnknown)))
    }

    /// Shared entry point for converting dropped/opened markdown files and
    /// notifying the UI. Replaces the duplicated logic previously living in
    /// both AppDelegate and MenuBarManager.
    @MainActor
    static func convertAndNotify(urls: [URL], formatting: FormattingSnapshot) {
        let markdownURLs = urls.filter(MarkdownFileConverter.supports)
        guard !markdownURLs.isEmpty else { return }

        let converter = MarkdownFileConverter(formatting: formatting)

        Task { @MainActor in
            for url in markdownURLs {
                let result = await Task.detached(priority: .userInitiated) {
                    converter.convertFile(at: url)
                }.value

                NotificationCenter.default.post(
                    name: .markdownFileConversionCompleted,
                    object: nil,
                    userInfo: ["result": result]
                )
            }
        }
    }

    private func nextAvailableOutputURL(for sourceURL: URL, startingAt initialSuffix: Int = 2) -> URL {
        let directoryURL = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var candidate = directoryURL.appendingPathComponent(baseName).appendingPathExtension("rtf")
        var suffix = initialSuffix

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL
                .appendingPathComponent("\(baseName) \(suffix)")
                .appendingPathExtension("rtf")
            suffix += 1
        }

        return candidate
    }
}
