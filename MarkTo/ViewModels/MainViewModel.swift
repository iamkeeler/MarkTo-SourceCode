import Foundation
import AppKit
import SwiftUI

private struct ConversionOutcome: @unchecked Sendable {
    let result: Result<NSAttributedString, MarkdownConversionError>
    let processingTime: TimeInterval
}

private struct FileConversionOutcome: @unchecked Sendable {
    let result: Result<MarkdownFileConversionResult, MarkdownFileConversionError>
}

@MainActor
final class MainViewModel: ObservableObject {
    @Published var markdownText: String = "" {
        didSet {
            if markdownText != oldValue {
                clearStatus()
            }
        }
    }
    @Published var isConverting: Bool = false
    @Published var statusMessage: String = ""
    @Published var isSuccess: Bool = false

    private var conversionTask: Task<Void, Never>?
    private var statusClearTask: Task<Void, Never>?

    // MARK: - Public Methods

    func convertToRTF() {
        guard !markdownText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Please enter some markdown text", isSuccess: false)
            return
        }

        isConverting = true
        clearStatus()

        let textToConvert = markdownText
        let converter = MarkdownConverter(
            formatting: FormattingPreferences.shared.snapshot()
        )

        conversionTask?.cancel()
        conversionTask = Task { [weak self] in
            let outcome = await Task.detached(priority: .userInitiated) {
                let startTime = CFAbsoluteTimeGetCurrent()
                let result = converter.convertToRTF(textToConvert)
                return ConversionOutcome(
                    result: result,
                    processingTime: CFAbsoluteTimeGetCurrent() - startTime
                )
            }.value

            guard !Task.isCancelled else { return }
            self?.isConverting = false
            self?.handleConversionResult(
                outcome.result,
                processingTime: outcome.processingTime
            )
        }
    }

    func loadFile(at url: URL) {
        let hasSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            markdownText = try String(contentsOf: url, encoding: .utf8)
            showStatus("Loaded \(url.lastPathComponent)", isSuccess: true)
        } catch {
            showStatus("Could not open \(url.lastPathComponent)", isSuccess: false)
        }
    }

    func convertMarkdownFile(at url: URL) {
        guard MarkdownFileConverter.supports(url) else {
            showStatus("Drop a .md or .markdown file", isSuccess: false)
            return
        }

        isConverting = true
        clearStatus()

        let converter = MarkdownFileConverter(
            formatting: FormattingPreferences.shared.snapshot()
        )

        conversionTask?.cancel()
        conversionTask = Task { [weak self] in
            let outcome = await Task.detached(priority: .userInitiated) {
                FileConversionOutcome(result: converter.convertFile(at: url))
            }.value

            guard !Task.isCancelled else { return }
            self?.isConverting = false
            self?.handleFileConversionResult(outcome.result)
        }
    }

    func handleExternalFileConversion(
        _ result: Result<MarkdownFileConversionResult, MarkdownFileConversionError>
    ) {
        handleFileConversionResult(result)
    }

    func clearText() {
        markdownText = ""
        clearStatus()
    }

    // MARK: - Private Methods

    private func handleConversionResult(_ result: Result<NSAttributedString, MarkdownConversionError>, processingTime: TimeInterval) {
        switch result {
        case .success(let attributedString):
            guard copyToClipboard(attributedString) else {
                showStatus("Could not write RTF to the clipboard", isSuccess: false)
                return
            }
            let timeText = String(format: "%.0f", processingTime * 1000)
            showStatus("RTF copied to clipboard! (\(timeText)ms)", isSuccess: true)
        case .failure(let error):
            showStatus("Error: \(error.localizedDescription)", isSuccess: false)
        }
    }

    private func handleFileConversionResult(
        _ result: Result<MarkdownFileConversionResult, MarkdownFileConversionError>
    ) {
        switch result {
        case .success(let output):
            markdownText = output.markdown
            showStatus("Created \(output.outputURL.lastPathComponent)", isSuccess: true)
        case .failure(let error):
            showStatus(error.localizedDescription, isSuccess: false)
        }
    }

    @discardableResult
    private func copyToClipboard(_ attributedString: NSAttributedString) -> Bool {
        let pasteboard = NSPasteboard.general
        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            return false
        }

        pasteboard.clearContents()
        let wroteRTF = pasteboard.setData(rtfData, forType: .rtf)
        let wrotePlainText = pasteboard.setString(attributedString.string, forType: .string)
        return wroteRTF && wrotePlainText
    }

    private func showStatus(_ message: String, isSuccess: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.statusMessage = message
            self.isSuccess = isSuccess
        }

        // Clear status after delay
        statusClearTask?.cancel()
        statusClearTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.clearStatus()
        }
    }

    private func clearStatus() {
        withAnimation(.easeInOut(duration: 0.3)) {
            statusMessage = ""
        }
        statusClearTask?.cancel()
        statusClearTask = nil
    }

    deinit {
        conversionTask?.cancel()
        statusClearTask?.cancel()
    }
}
