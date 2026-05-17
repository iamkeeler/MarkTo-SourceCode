import XCTest
@testable import MarkTo

final class RTFToMarkdownConverterTests: XCTestCase {

    var converter: RTFToMarkdownConverter!

    override func setUp() {
        super.setUp()
        converter = RTFToMarkdownConverter()
    }

    func testBasicText() {
        let text = NSAttributedString(string: "Hello world")
        XCTAssertEqual(converter.convertToMarkdown(text), "Hello world")
    }

    func testBoldText() {
        let attrText = NSMutableAttributedString(string: "Hello world")
        attrText.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 12), range: NSRange(location: 0, length: 5))
        XCTAssertEqual(converter.convertToMarkdown(attrText), "**Hello** world")
    }

    func testItalicText() {
        let fontManager = NSFontManager.shared
        let italicFont = fontManager.convert(NSFont.systemFont(ofSize: 12), toHaveTrait: .italicFontMask)
        let attrText = NSMutableAttributedString(string: "Hello world")
        attrText.addAttribute(.font, value: italicFont, range: NSRange(location: 6, length: 5))
        XCTAssertEqual(converter.convertToMarkdown(attrText), "Hello *world*")
    }

    func testEscaping() {
        let text = NSAttributedString(string: "This has * and _ inside")
        XCTAssertEqual(converter.convertToMarkdown(text), "This has \\* and \\_ inside")
    }
}
