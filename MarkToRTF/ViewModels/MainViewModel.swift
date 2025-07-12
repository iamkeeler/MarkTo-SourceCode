import Foundation
import Combine
import AppKit
import SwiftUI

class MainViewModel: ObservableObject {
    @Published var markdownText: String = ""
    @Published var isConverting: Bool = false
    @Published var statusMessage: String = ""
    @Published var isSuccess: Bool = false
    
    private let markdownConverter = MarkdownConverter()
    private var statusTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Debounce text changes to avoid excessive processing
        $markdownText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.clearStatus()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func convertToRTF() {
        guard !markdownText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStatus("Please enter some markdown text", isSuccess: false)
            return
        }
        
        isConverting = true
        clearStatus()
        
        // Perform conversion on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = self.markdownConverter.convertToRTF(self.markdownText)
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.isConverting = false
                self.handleConversionResult(result, processingTime: processingTime)
            }
        }
    }
    
    func loadClipboardContent() {
        let pasteboard = NSPasteboard.general
        
        // Try to get text from clipboard
        guard let clipboardText = pasteboard.string(forType: .string) else { return }
        
        // Only load if it looks like markdown and isn't too long
        if clipboardText.count < 10000 && containsMarkdownSyntax(clipboardText) {
            markdownText = clipboardText
            showStatus("Loaded content from clipboard", isSuccess: true)
        }
    }
    
    func clearText() {
        markdownText = ""
        clearStatus()
    }
    
    // MARK: - Private Methods
    
    private func handleConversionResult(_ result: Result<String, MarkdownConversionError>, processingTime: TimeInterval) {
        switch result {
        case .success(let rtfString):
            copyToClipboard(rtfString)
            let timeText = String(format: "%.0f", processingTime * 1000)
            showStatus("RTF copied to clipboard! (\(timeText)ms)", isSuccess: true)
        case .failure(let error):
            showStatus("Error: \(error.localizedDescription)", isSuccess: false)
        }
    }
    
    private func containsMarkdownSyntax(_ text: String) -> Bool {
        let markdownPatterns = [
            #"^#{1,6}\s"#,          // Headers
            #"\*\*.*\*\*"#,         // Bold
            #"\*.*\*"#,             // Italic
            #"`.*`"#,               // Code
            #"^\s*[-\*\+]\s"#,      // Lists
            #"^\s*\d+\.\s"#,        // Numbered lists
            #"```"#,                // Code blocks
            #"\[.*\]\(.*\)"#        // Links
        ]
        
        return markdownPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
    
    private func copyToClipboard(_ rtfString: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Convert RTF string back to attributed string and then to RTF data
        if let rtfData = rtfString.data(using: .utf8),
           let attributedString = try? NSAttributedString(
               data: rtfData,
               options: [.documentType: NSAttributedString.DocumentType.rtf],
               documentAttributes: nil
           ) {
            
            // Set both RTF and plain text on clipboard
            if let newRTFData = try? attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) {
                pasteboard.setData(newRTFData, forType: .rtf)
            }
            
            pasteboard.setString(attributedString.string, forType: .string)
        } else {
            // Fallback: just copy as plain text
            pasteboard.setString(rtfString, forType: .string)
        }
    }
    
    private func showStatus(_ message: String, isSuccess: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.statusMessage = message
            self.isSuccess = isSuccess
        }
        
        // Clear status after delay
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.clearStatus()
        }
    }
    
    private func clearStatus() {
        withAnimation(.easeInOut(duration: 0.3)) {
            statusMessage = ""
        }
        statusTimer?.invalidate()
    }
    
    deinit {
        statusTimer?.invalidate()
        cancellables.removeAll()
    }
}
