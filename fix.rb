content = File.read("MarkTo/ViewModels/MainViewModel.swift")

# Fix missing properties
content.sub!(/    @Published var isSuccess: Bool = false\n/, "    @Published var isSuccess: Bool = false\n    @Published var hasRTFInClipboard: Bool = false\n\n    private let rtfToMarkdownConverter = RTFToMarkdownConverter()\n    private var clipboardTimer: Timer?\n    private var lastClipboardChangeCount: Int = 0\n")

# Remove broken tail end of loadClipboardContent that wasn't cleaned up correctly
content.sub!(/        \/\/ Only load if it looks like markdown and isn't too long\n        if clipboardText\.count < 10000 && containsMarkdownSyntax\(clipboardText\) \{\n            markdownText = clipboardText\n            showStatus\("Loaded content from clipboard", isSuccess: true\)\n        \}\n    \}/, "")

File.write("MarkTo/ViewModels/MainViewModel.swift", content)
