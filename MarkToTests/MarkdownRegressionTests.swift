import XCTest
import AppKit
@testable import MarkTo

final class MarkdownRegressionTests: XCTestCase {
    func testNestedListsPreserveIndentation() throws {
        let markdown = """
        - Parent
          - Child
        """
        let attributed = try XCTUnwrap(MarkdownConverter().convertToRTF(markdown).value)
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
            MarkdownConverter().convertToRTF("- [x] Complete\n- [ ] Pending").value
        )

        XCTAssertTrue(attributed.string.contains("☑ Complete"))
        XCTAssertTrue(attributed.string.contains("☐ Pending"))
        XCTAssertFalse(attributed.string.contains("[x]"))
    }

    func testProsePipeIsNotATable() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToRTF("Use A | B in prose").value
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
        let attributed = try XCTUnwrap(converter.convertToRTF("Customized body").value)
        let font = try XCTUnwrap(
            attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        )

        XCTAssertEqual(font.pointSize, 19)
    }

    func testEscapedEmphasisRemainsLiteral() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToRTF(#"\*literal\* and \_also literal\_"#).value
        )

        XCTAssertTrue(attributed.string.contains("*literal* and _also literal_"))
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        XCTAssertFalse(font.fontDescriptor.symbolicTraits.contains(.italic))
    }

    func testInlineCodeDoesNotParseNestedMarkdown() throws {
        let attributed = try XCTUnwrap(
            MarkdownConverter().convertToRTF("`**literal**` outside").value
        )

        XCTAssertTrue(attributed.string.contains("**literal** outside"))
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        XCTAssertTrue(font.familyName?.localizedCaseInsensitiveContains("mono") == true)
    }
}

private extension Result where Failure == MarkdownConversionError {
    var value: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }
}
