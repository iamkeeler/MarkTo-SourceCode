import XCTest
import AppKit
@testable import MarkTo

final class MarkdownRegressionTests: XCTestCase {
    func testNestedListsPreserveIndentation() throws {
        let markdown = """
        - Parent
          - Child
        """
        let attributed = try XCTUnwrap(MarkdownConverter().convertToAttributedString(markdown).value)
        let parentRange = (attributed.string as NSString).range(of: "Parent")
        let childRange = (attributed.string as NSString).range(of: "Child")
        let parentStyle = attributed.attribute(.paragraphStyle, at: parentRange.location, effectiveRange: nil) as? NSParagraphStyle
        let childStyle = attributed.attribute(.paragraphStyle, at: childRange.location, effectiveRange: nil) as? NSParagraphStyle

        XCTAssertGreaterThan(
            try XCTUnwrap(childStyle).firstLineHeadIndent,
            try XCTUnwrap(parentStyle).firstLineHeadIndent
        )
    }

    func testTaskListsRenderCheckboxes() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("- [x] Complete\n- [ ] Pending").value
        )

        XCTAssertTrue(attributed.string.contains("☑ Complete"))
        XCTAssertTrue(attributed.string.contains("☐ Pending"))
        XCTAssertFalse(attributed.string.contains("[x]"))
    }

    func testProsePipeIsNotATable() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("Use A | B in prose").value
        )

        XCTAssertTrue(attributed.string.contains("Use A | B in prose"))
        XCTAssertFalse(attributed.string.contains("─┼─"))
    }

    func testFormattingSnapshotAffectsOutput() throws {
        var settings = FormattingSnapshot.defaults.settings
        settings[.body] = TextFormatting(
            fontSize: 19,
            fontWeight: .medium,
            lineSpacing: 1.5
        )
        let converter = MarkdownConverter(
            formatting: FormattingSnapshot(settings: settings)
        )
        let attributed = try XCTUnwrap(converter.convertToAttributedString("Customized body").value)
        let font = try XCTUnwrap(
            attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        )

        XCTAssertEqual(font.pointSize, 19)
    }

    func testEscapedEmphasisRemainsLiteral() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString(#"\*literal\* and \_also literal\_"#).value
        )

        XCTAssertTrue(attributed.string.contains("*literal* and _also literal_"))
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        XCTAssertFalse(font.fontDescriptor.symbolicTraits.contains(.italic))
    }

    func testInlineCodeDoesNotParseNestedMarkdown() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("`**literal**` outside").value
        )

        XCTAssertTrue(attributed.string.contains("**literal** outside"))
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        XCTAssertTrue(font.familyName?.localizedCaseInsensitiveContains("mono") == true)
    }

    // MARK: - Code review regression tests (2026-09-12)

    func testTrimmedListPatternsMatch() {
        // H1: the trimmed patterns previously used doubled backslashes in a
        // raw string and matched a literal backslash + "s" instead of whitespace.
        let cases: [(NSRegularExpression, String)] = [
            (ParsingContext.unorderedListTrimmedPattern, "- item"),
            (ParsingContext.orderedListTrimmedPattern, "1. item"),
            (ParsingContext.taskListTrimmedPattern, "- [x] item"),
            (ParsingContext.anyListTrimmedPattern, "12. item"),
        ]
        for (pattern, line) in cases {
            let range = NSRange(location: 0, length: (line as NSString).length)
            XCTAssertNotNil(
                pattern.firstMatch(in: line, options: [], range: range),
                "Trimmed pattern should match '\(line)'"
            )
        }
    }

    func testHeaderWithPipesIsNotTable() throws {
        // M1: "# | a |" is a header, not a table row.
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("# | a |").value
        )
        XCTAssertFalse(attributed.string.contains("│"), "Header must not render as a table")
        XCTAssertTrue(attributed.string.contains("| a |"))
    }

    func testUnclosedCodeFenceRendersAsCode() throws {
        // M5: an unclosed fence swallows the rest of the document as code.
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("```swift\nlet x = 1").value
        )
        let string = attributed.string
        XCTAssertTrue(string.contains("let x = 1"))
        XCTAssertFalse(string.contains("```"), "Fence markers must not leak into output")
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        XCTAssertTrue(font.familyName?.localizedCaseInsensitiveContains("mono") == true)
    }

    func testSpacedHorizontalRule() throws {
        // M7: "- - -" is a horizontal rule, not a list item.
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("- - -").value
        )
        XCTAssertTrue(attributed.string.contains("─"), "Spaced rule should render as a rule")
        XCTAssertFalse(attributed.string.contains("- - -"))
    }

    func testTripleEmphasis() throws {
        // M8: "***both***" is bold + italic, not bold with a stray "*".
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("***both***").value
        )
        XCTAssertFalse(attributed.string.contains("*"))
        XCTAssertTrue(attributed.string.contains("both"))
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.italic))
    }

    func testImageAltTextWithUnderscores() throws {
        // M3: underscores in image alt text must not be read as emphasis.
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("![a_b_c](https://example.com/i.png)").value
        )
        XCTAssertTrue(attributed.string.contains("[Image: a_b_c]"))
    }

    func testBareURLKeepsTrailingSlash() throws {
        // M4: the old pattern's trailing \b dropped URL-final slashes.
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("Visit https://example.com/ today").value
        )
        let linkRange = (attributed.string as NSString).range(of: "https://example.com/")
        XCTAssertNotEqual(linkRange.location, NSNotFound)
        let link = try XCTUnwrap(attributed.attribute(.link, at: linkRange.location, effectiveRange: nil) as? String)
        XCTAssertEqual(link, "https://example.com/")
    }

    func testLongBareURLIsLinkified() throws {
        // M4: URLs longer than 100 characters must still linkify.
        let url = "https://example.com/" + String(repeating: "a", count: 150)
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("See \(url)").value
        )
        let linkRange = (attributed.string as NSString).range(of: url)
        XCTAssertNotEqual(linkRange.location, NSNotFound)
        XCTAssertNotNil(attributed.attribute(.link, at: linkRange.location, effectiveRange: nil))
    }

    func testBlockquoteVariants() throws {
        // M6: bare ">", ">quote", and nested ">>" are all blockquotes.
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString(">\n>quote\n>> nested").value
        )
        let string = attributed.string
        XCTAssertTrue(string.contains("quote"))
        XCTAssertTrue(string.contains("nested"))
        XCTAssertTrue(string.contains("▌"))
    }

    func testHeaderClosingHashes() throws {
        // M11: only a space-prefixed closing sequence is stripped; "# C#" keeps "#".
        let sharp = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("# C#").value
        )
        XCTAssertTrue(sharp.string.contains("C#"))

        let closed = try XCTUnwrap(
            MarkdownConverter().convertToAttributedString("## Title ##").value
        )
        XCTAssertFalse(closed.string.contains("#"))
        XCTAssertTrue(closed.string.contains("Title"))
    }
}

private extension Result where Failure == MarkdownConversionError {
    var value: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }
}
