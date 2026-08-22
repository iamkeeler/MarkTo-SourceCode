import Foundation
import AppKit

// MARK: - Test Suite Runner for MarkTo

@main
struct TestRunner {
    static var totalTests = 0
    static var passedTests = 0
    static var failedTests = 0

    static func assert(_ condition: Bool, _ message: String, line: Int = #line) {
        totalTests += 1
        if condition {
            passedTests += 1
            print("  ✅ PASS: \(message)")
        } else {
            failedTests += 1
            print("  ❌ FAIL: \(message) (at line \(line))")
        }
    }

    static func runSuite(_ name: String, block: () throws -> Void) {
        print("\n📦 Running Test Suite: \(name)")
        print(String(repeating: "-", count: 50))
        do {
            try block()
        } catch {
            print("  ❌ Suite threw unexpected error: \(error)")
            failedTests += 1
        }
    }

    @MainActor
    static func main() {
        print("🚀 STARTING MARKTO TEST SUITE")
        print(String(repeating: "=", count: 50))

        // MARK: - 1. AppPreferences Tests
        runSuite("AppPreferences & Version Resolution") {
            let suiteName = "com.attachdesign.markto.testsuite"
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)

            // Default values
            let prefs = AppPreferences(userDefaults: defaults, appliesSystemChanges: false)
            assert(prefs.hideOnStartup == false, "hideOnStartup defaults to false")
            assert(prefs.hideDockIcon == false, "hideDockIcon defaults to false")
            assert(prefs.startAtLogin == false, "startAtLogin defaults to false")

            // hideOnStartup persistence
            prefs.hideOnStartup = true
            assert(defaults.bool(forKey: AppPreferences.Keys.hideOnStartup) == true, "UserDefaults persists hideOnStartup = true")

            let reloadedPrefs1 = AppPreferences(userDefaults: defaults, appliesSystemChanges: false)
            assert(reloadedPrefs1.hideOnStartup == true, "Reloaded instance has hideOnStartup = true")

            reloadedPrefs1.hideOnStartup = false
            assert(defaults.bool(forKey: AppPreferences.Keys.hideOnStartup) == false, "UserDefaults persists hideOnStartup = false")

            // hideDockIcon persistence
            prefs.hideDockIcon = true
            assert(defaults.bool(forKey: AppPreferences.Keys.hideDockIcon) == true, "UserDefaults persists hideDockIcon = true")

            let reloadedPrefs2 = AppPreferences(userDefaults: defaults, appliesSystemChanges: false)
            assert(reloadedPrefs2.hideDockIcon == true, "Reloaded instance has hideDockIcon = true")

            // Dynamic version formatting test
            func formatVersion(from dict: [String: Any]?) -> String {
                let version = dict?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                let build = dict?["CFBundleVersion"] as? String ?? ""
                return build.isEmpty ? version : "\(version) (\(build))"
            }

            assert(formatVersion(from: ["CFBundleShortVersionString": "1.0.3", "CFBundleVersion": "12"]) == "1.0.3 (12)", "Formats full version + build")
            assert(formatVersion(from: ["CFBundleShortVersionString": "1.0.3"]) == "1.0.3", "Formats version without build")
            assert(formatVersion(from: [:]) == "1.0.0", "Fallback for empty dictionary")
            assert(formatVersion(from: nil) == "1.0.0", "Fallback for nil dictionary")

            defaults.removePersistentDomain(forName: suiteName)
        }

        // MARK: - 2. UI & ViewModel Tests
        runSuite("UI & ViewModels State & Interactions") {
            // MainViewModel tests
            let mainVM = MainViewModel()
            assert(mainVM.markdownText.isEmpty, "MainViewModel starts with empty markdown text")
            assert(mainVM.isConverting == false, "MainViewModel isConverting starts false")

            mainVM.markdownText = "   "
            mainVM.convertToRTF()
            assert(mainVM.statusMessage == "Please enter some markdown text", "MainViewModel warns on empty text conversion")

            mainVM.markdownText = "# Hello World"
            mainVM.clearText()
            assert(mainVM.markdownText.isEmpty, "MainViewModel clearText empties text")
            assert(mainVM.statusMessage.isEmpty, "MainViewModel clearText clears status message")

            // FormattingViewModel tests
            let formattingSuiteName = "com.attachdesign.markto.formatting-tests"
            let formattingDefaults = UserDefaults(suiteName: formattingSuiteName)!
            formattingDefaults.removePersistentDomain(forName: formattingSuiteName)
            let formattingVM = FormattingViewModel(
                formattingPreferences: FormattingPreferences(userDefaults: formattingDefaults)
            )
            assert(formattingVM.selectedElement == .body, "FormattingViewModel defaults to body element")
            assert(formattingVM.selectedCategory == .text, "FormattingViewModel defaults to text category")

            formattingVM.selectElement(.header1)
            assert(formattingVM.selectedElement == .header1, "FormattingViewModel selects heading 1")
            assert(formattingVM.selectedCategory == .headers, "FormattingViewModel auto-selects headers category")

            formattingVM.searchText = "Header 1"
            assert(formattingVM.filteredElements.count == 1, "FormattingViewModel filters by search text")
            formattingVM.searchText = ""

            formattingVM.updateFontSize(18.0)
            assert(formattingVM.currentFormatting.fontSize == 18.0, "FormattingViewModel updates font size")

            formattingVM.applyPreset(.compact)
            assert(formattingVM.currentFormatting.lineSpacing == 1.0, "FormattingViewModel applies compact preset")

            formattingVM.resetCurrentElement()
            assert(formattingVM.showResetAlert == true, "FormattingViewModel triggers reset alert")
            formattingVM.confirmResetElement()
            assert(formattingVM.showResetAlert == false || formattingVM.elementToReset == nil, "FormattingViewModel completes reset")

            let export = formattingVM.exportFormatting()
            assert(export.contains("MarkTo Formatting Settings"), "FormattingViewModel exports configuration")

            let preview = formattingVM.getPreviewAttributedString(for: .header1)
            assert(!preview.string.isEmpty, "FormattingViewModel produces preview attributed string")
        }

        // MARK: - 3. Markdown Table Conversion Tests
        runSuite("Markdown Table Conversion") {
            let converter = MarkdownConverter()

            // Simple table
            let simpleTable = """
            | Name | Age | City |
            |------|-----|------|
            | John | 25 | NYC |
            | Jane | 30 | LA |
            """
            if case .success(let attr) = converter.convertToRTF(simpleTable) {
                let str = attr.string
                assert(str.contains("Name") && str.contains("Age") && str.contains("City"), "Table contains headers")
                assert(str.contains("John") && str.contains("Jane") && str.contains("NYC"), "Table contains data rows")
            } else {
                assert(false, "Simple table conversion succeeded")
            }

            // Formatted table with bold and italic
            let formattedTable = """
            | **Feature** | *Status* | `Priority` |
            |-------------|----------|------------|
            | **Tables** | *In Progress* | `High` |
            """
            if case .success(let attr) = converter.convertToRTF(formattedTable) {
                let str = attr.string
                assert(str.contains("Feature") && str.contains("Tables"), "Formatted table has content")
                assert(str.contains("Status") && str.contains("In Progress"), "Formatted table has status content")

                var foundBold = false
                var foundItalic = false
                let fullRange = NSRange(location: 0, length: attr.length)
                attr.enumerateAttributes(in: fullRange, options: []) { attrs, _, _ in
                    if let font = attrs[.font] as? NSFont {
                        if font.fontDescriptor.symbolicTraits.contains(.bold) { foundBold = true }
                        if font.fontDescriptor.symbolicTraits.contains(.italic) { foundItalic = true }
                    }
                }
                assert(foundBold, "Table preserves bold formatting")
                assert(foundItalic, "Table preserves italic formatting")
            } else {
                assert(false, "Formatted table conversion succeeded")
            }

            // Minimal table
            let minimalTable = """
            | A | B |
            |---|---|
            | 1 | 2 |
            """
            if case .success(let attr) = converter.convertToRTF(minimalTable) {
                assert(attr.string.contains("A") && attr.string.contains("1"), "Minimal table converted correctly")
            } else {
                assert(false, "Minimal table conversion succeeded")
            }

            // Separator detection
            let inlineProcessor = InlineProcessor()
            let tableProcessor = TableProcessor(inlineProcessor: inlineProcessor)
            assert(tableProcessor.isHeaderSeparator("|---|---|") == true, "Standard separator detected")
            assert(tableProcessor.isHeaderSeparator("|:--:|:--|") == true, "Colons in separator detected")
            assert(tableProcessor.isHeaderSeparator("| : | : |") == false, "Missing dashes correctly rejected")
            assert(tableProcessor.isHeaderSeparator("|---x---|") == false, "Invalid characters rejected")
        }

        // MARK: - 4. General Markdown Features Tests
        runSuite("General Markdown Conversion") {
            let converter = MarkdownConverter()

            // Headings
            let headings = """
            # Heading 1
            ## Heading 2
            ### Heading 3
            """
            if case .success(let attr) = converter.convertToRTF(headings) {
                assert(attr.string.contains("Heading 1"), "Heading 1 converted")
                assert(attr.string.contains("Heading 2"), "Heading 2 converted")
                assert(attr.string.contains("Heading 3"), "Heading 3 converted")
            } else {
                assert(false, "Headings converted successfully")
            }

            // Lists
            let lists = """
            - Item 1
            - Item 2
              - Nested item
            """
            if case .success(let attr) = converter.convertToRTF(lists) {
                assert(attr.string.contains("Item 1") && attr.string.contains("Nested item"), "List items converted")

                let parentRange = (attr.string as NSString).range(of: "Item 1")
                let nestedRange = (attr.string as NSString).range(of: "Nested item")
                let parentStyle = attr.attribute(.paragraphStyle, at: parentRange.location, effectiveRange: nil) as? NSParagraphStyle
                let nestedStyle = attr.attribute(.paragraphStyle, at: nestedRange.location, effectiveRange: nil) as? NSParagraphStyle
                assert(
                    (nestedStyle?.firstLineHeadIndent ?? 0) > (parentStyle?.firstLineHeadIndent ?? 0),
                    "Nested lists preserve deeper indentation"
                )
            } else {
                assert(false, "Lists converted successfully")
            }

            let tasks = "- [x] Complete\n- [ ] Pending"
            if case .success(let attr) = converter.convertToRTF(tasks) {
                assert(attr.string.contains("☑ Complete"), "Checked task list renders a checked box")
                assert(attr.string.contains("☐ Pending"), "Unchecked task list renders an empty box")
                assert(!attr.string.contains("[x]"), "Task list syntax is removed from output")
            } else {
                assert(false, "Task lists converted successfully")
            }

            if case .success(let attr) = converter.convertToRTF("Use A | B in prose") {
                assert(attr.string.contains("Use A | B in prose"), "A prose pipe is not misclassified as a table")
                assert(!attr.string.contains("─┼─"), "A prose pipe does not generate table separators")
            } else {
                assert(false, "Prose containing a pipe converted successfully")
            }

            var customSettings = FormattingSnapshot.defaults.settings
            customSettings[.body] = TextFormatting(fontSize: 19, fontWeight: .medium, lineSpacing: 1.5)
            let customizedConverter = MarkdownConverter(
                formatting: FormattingSnapshot(settings: customSettings)
            )
            if case .success(let attr) = customizedConverter.convertToRTF("Customized body") {
                let font = attr.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
                assert(font?.pointSize == 19, "Formatting preferences affect converted body text")
            } else {
                assert(false, "Customized formatting converted successfully")
            }

            if case .success(let attr) = converter.convertToRTF(#"\*literal\* and \_also literal\_"#) {
                assert(
                    attr.string.contains("*literal* and _also literal_"),
                    "Escaped emphasis remains literal"
                )
            } else {
                assert(false, "Escaped emphasis converted successfully")
            }

            if case .success(let attr) = converter.convertToRTF("`**literal**` outside") {
                assert(
                    attr.string.contains("**literal** outside"),
                    "Inline code does not parse nested Markdown"
                )
            } else {
                assert(false, "Inline code converted successfully")
            }

            // Code blocks
            let codeBlock = """
            ```swift
            let x = 42
            print(x)
            ```
            """
            if case .success(let attr) = converter.convertToRTF(codeBlock) {
                assert(attr.string.contains("let x = 42"), "Code block converted")
            } else {
                assert(false, "Code block converted successfully")
            }
        }

        // MARK: - 5. End-to-End Paste & Full RTF Document Conversion
        runSuite("End-to-End Clipboard Paste & Full Document Conversion") {
            let sampleDoc = """
            # Project Roadmap

            ## Overview
            This is an **important** document detailing the *MarkTo* release.
            We need to ensure ~~obsolete~~ features are removed and `newFeature()` is implemented.

            ### Action Items
            - [x] Review code quality
            - [ ] Add comprehensive tests
              - Nested item with **bold** text
              - Nested item with `code` span

            1. First step
            2. Second step

            > **Note:** Always verify formatting in Rich Text editors.

            ### Architecture Table
            | Component | Status | Priority | Link |
            | :--- | :--- | :--- | :--- |
            | **Converter** | *Complete* | `P0` | [Docs](https://attach.design) |
            | **UI Settings** | *Verified* | `P1` | [Settings](https://attach.design/settings) |

            ```swift
            struct MarkToRelease {
                let version = "1.0.3"
                let isReady = true
            }
            ```

            Visit [Attach Design](https://attach.design) for more details.
            """

            // 1. Exercise clipboard-content validation without depending on a
            // GUI pasteboard server in headless CI.
            let vm = MainViewModel()
            vm.loadClipboardContent(sampleDoc)
            assert(vm.markdownText == sampleDoc, "MainViewModel accepts valid markdown clipboard content")

            // 2. Convert markdown to RTF
            let converter = MarkdownConverter()
            let result = converter.convertToRTF(vm.markdownText)

            guard case .success(let attributedString) = result else {
                assert(false, "Full document conversion produced success result")
                return
            }
            assert(true, "Full document conversion produced success result")

            // 3. Generate an RTF byte payload
            guard let rtfData = try? attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) else {
                assert(false, "Serialized attributed string into RTF binary payload")
                return
            }
            assert(rtfData.count > 0, "Serialized attributed string into non-empty RTF binary payload")

            // 4. Simulate a destination app (Pages / Word / TextEdit) decoding
            // the exact RTF payload that MarkTo writes to the pasteboard.
            guard let destinationAttr = try? NSAttributedString(
                    data: rtfData,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
            ) else {
                assert(false, "Destination app successfully parsed RTF from clipboard")
                return
            }
            assert(true, "Destination app successfully parsed RTF from clipboard")

            let pastedStr = destinationAttr.string
            assert(pastedStr.contains("Project Roadmap"), "Pasted RTF contains H1 title")
            assert(pastedStr.contains("Overview"), "Pasted RTF contains H2 title")
            assert(pastedStr.contains("Action Items"), "Pasted RTF contains H3 title")
            assert(pastedStr.contains("important"), "Pasted RTF contains bold text")
            assert(pastedStr.contains("MarkTo"), "Pasted RTF contains italic text")
            assert(pastedStr.contains("newFeature()"), "Pasted RTF contains inline code")
            assert(pastedStr.contains("First step"), "Pasted RTF contains numbered list")
            assert(pastedStr.contains("Component"), "Pasted RTF contains table header")
            assert(pastedStr.contains("Converter"), "Pasted RTF contains table cell")
            assert(pastedStr.contains("struct MarkToRelease"), "Pasted RTF contains code block")

            // 6. Verify styling traits in the destination parsed RTF
            var hasBoldTrait = false
            var hasItalicTrait = false
            var hasCustomFontSize = false
            var hasLinkAttribute = false

            let fullRange = NSRange(location: 0, length: destinationAttr.length)
            destinationAttr.enumerateAttributes(in: fullRange, options: []) { attrs, _, _ in
                if let font = attrs[.font] as? NSFont {
                    if font.fontDescriptor.symbolicTraits.contains(.bold) { hasBoldTrait = true }
                    if font.fontDescriptor.symbolicTraits.contains(.italic) { hasItalicTrait = true }
                    if font.pointSize >= 18 { hasCustomFontSize = true }
                }
                if attrs[.link] != nil { hasLinkAttribute = true }
            }

            assert(hasBoldTrait, "Pasted RTF preserves bold traits")
            assert(hasItalicTrait, "Pasted RTF preserves italic traits")
            assert(hasCustomFontSize, "Pasted RTF preserves header font hierarchy")
            assert(hasLinkAttribute, "Pasted RTF preserves hyperlink attributes")
        }


        // MARK: - Final Summary
        print("\n" + String(repeating: "=", count: 50))
        print("📊 TEST SUMMARY")
        print("Total tests run: \(totalTests)")
        print("Passed:          \(passedTests) ✅")
        print("Failed:          \(failedTests) ❌")
        print(String(repeating: "=", count: 50))

        if failedTests > 0 {
            exit(1)
        } else {
            print("\n🎉 ALL TESTS PASSED SUCCESSFULLY!\n")
            exit(0)
        }
    }
}
