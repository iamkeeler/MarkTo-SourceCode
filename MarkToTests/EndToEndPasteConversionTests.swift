import XCTest
import AppKit
@testable import MarkTo

@MainActor
final class EndToEndPasteConversionTests: XCTestCase {

    private let sampleMarkdown = """
    # Project Plan

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

    func testFullRTFConversionWorkflow() {
        // 1. Perform conversion directly with MarkdownConverter to inspect the exact RTF.
        let converter = MarkdownConverter()
        let conversionResult = converter.convertToRTF(sampleMarkdown)

        guard case .success(let attributedString) = conversionResult else {
            XCTFail("Conversion failed unexpectedly")
            return
        }

        // 2. Verify RTF data can be generated.
        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            XCTFail("Failed to serialize NSAttributedString to RTF data")
            return
        }

        // 3. Simulate a destination app decoding the payload MarkTo writes.
        guard let pastedAttributedString = try? NSAttributedString(
                data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
        ) else {
            XCTFail("Destination app failed to read valid RTF from pasteboard")
            return
        }

        let pastedString = pastedAttributedString.string

        // 4. Verify converted content.
        XCTAssertTrue(pastedString.contains("Project Plan"), "Header 1 text present")
        XCTAssertTrue(pastedString.contains("Overview"), "Header 2 text present")
        XCTAssertTrue(pastedString.contains("Action Items"), "Header 3 text present")
        XCTAssertTrue(pastedString.contains("important"), "Bold word present")
        XCTAssertTrue(pastedString.contains("MarkTo"), "Italic word present")
        XCTAssertTrue(pastedString.contains("newFeature()"), "Inline code present")
        XCTAssertTrue(pastedString.contains("Review code quality"), "List items present")
        XCTAssertTrue(pastedString.contains("Component"), "Table headers present")
        XCTAssertTrue(pastedString.contains("Converter"), "Table rows present")
        XCTAssertTrue(pastedString.contains("struct MarkToRelease"), "Code block content present")

        // 5. Verify rich text attributes throughout the pasted string.
        var hasBoldTrait = false
        var hasItalicTrait = false
        var hasLinkAttribute = false
        var hasCustomFontSize = false

        let fullRange = NSRange(location: 0, length: pastedAttributedString.length)
        pastedAttributedString.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            if let font = attrs[.font] as? NSFont {
                if font.fontDescriptor.symbolicTraits.contains(.bold) {
                    hasBoldTrait = true
                }
                if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    hasItalicTrait = true
                }
                if font.pointSize >= 18 {
                    hasCustomFontSize = true
                }
            }
            if attrs[.link] != nil {
                hasLinkAttribute = true
            }
        }

        XCTAssertTrue(hasBoldTrait, "Pasted RTF must contain bold styling traits")
        XCTAssertTrue(hasItalicTrait, "Pasted RTF must contain italic styling traits")
        XCTAssertTrue(hasCustomFontSize, "Pasted RTF must contain larger font sizes for headings")
        XCTAssertTrue(hasLinkAttribute, "Pasted RTF must contain clickable hyperlinks")
    }

    func testMarkdownFileConversionCreatesSiblingRTFWithoutOverwritingExistingExport() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkToFileConversion-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sourceURL = directory.appendingPathComponent("Release Notes.md")
        let existingOutputURL = directory.appendingPathComponent("Release Notes.rtf")
        try "# Release Notes\n\n**Ready** for launch.".write(to: sourceURL, atomically: true, encoding: .utf8)
        try Data("existing export".utf8).write(to: existingOutputURL)

        let result = MarkdownFileConverter().convertFile(at: sourceURL)

        guard case .success(let conversion) = result else {
            XCTFail("Markdown file conversion should succeed")
            return
        }

        XCTAssertEqual(conversion.outputURL.lastPathComponent, "Release Notes 2.rtf")
        XCTAssertEqual(conversion.markdown, "# Release Notes\n\n**Ready** for launch.")
        XCTAssertEqual(try Data(contentsOf: existingOutputURL), Data("existing export".utf8))

        let exportedDocument = try NSAttributedString(
            url: conversion.outputURL,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        XCTAssertTrue(exportedDocument.string.contains("Release Notes"))
        XCTAssertTrue(exportedDocument.string.contains("Ready"))
    }

    func testMarkdownFileConversionRejectsUnsupportedFiles() {
        let result = MarkdownFileConverter().convertFile(at: URL(fileURLWithPath: "/tmp/NotMarkdown.txt"))

        guard case .failure(.unsupportedFile) = result else {
            XCTFail("Only registered Markdown file extensions should be converted")
            return
        }
    }
}
