import XCTest
@testable import MarkTo

final class MarkdownConverterTests: XCTestCase {
    
    var converter: MarkdownConverter!
    
    override func setUpWithError() throws {
        converter = MarkdownConverter()
    }
    
    override func tearDownWithError() throws {
        converter = nil
    }
    
    func testEmptyInput() throws {
        let result = converter.convertToRTF("")
        
        switch result {
        case .success:
            XCTFail("Empty input should return failure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidInput)
        }
    }
    
    func testWhitespaceOnlyInput() throws {
        let result = converter.convertToRTF("   \n  \t  ")
        
        switch result {
        case .success:
            XCTFail("Whitespace-only input should return failure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidInput)
        }
    }
    
    func testSimpleTextConversion() throws {
        let markdown = "Hello, World!"
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let rtf):
            XCTAssertTrue(rtf.contains("Hello, World!"))
        case .failure(let error):
            XCTFail("Simple text conversion failed: \(error)")
        }
    }
    
    func testBoldTextConversion() throws {
        let markdown = "This is **bold** text."
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let rtf):
            XCTAssertTrue(rtf.contains("bold"))
        case .failure(let error):
            XCTFail("Bold text conversion failed: \(error)")
        }
    }
    
    func testItalicTextConversion() throws {
        let markdown = "This is *italic* text."
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let rtf):
            XCTAssertTrue(rtf.contains("italic"))
        case .failure(let error):
            XCTFail("Italic text conversion failed: \(error)")
        }
    }
    
    func testHeadingConversion() throws {
        let markdown = "# Main Heading\n## Sub Heading"
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let rtf):
            XCTAssertTrue(rtf.contains("Main Heading"))
            XCTAssertTrue(rtf.contains("Sub Heading"))
        case .failure(let error):
            XCTFail("Heading conversion failed: \(error)")
        }
    }
    
    func testCodeConversion() throws {
        let markdown = "Here is some `inline code` in text."
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let rtf):
            XCTAssertTrue(rtf.contains("inline code"))
        case .failure(let error):
            XCTFail("Code conversion failed: \(error)")
        }
    }
    
    func testListConversion() throws {
        let markdown = "- Item 1\n- Item 2\n+ Item 3"
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let rtf):
            XCTAssertTrue(rtf.contains("Item 1"))
            XCTAssertTrue(rtf.contains("Item 2"))
            XCTAssertTrue(rtf.contains("Item 3"))
        case .failure(let error):
            XCTFail("List conversion failed: \(error)")
        }
    }
    
    func testPerformanceExample() throws {
        let markdown = String(repeating: "# Heading\n\nThis is **bold** and *italic* text with `code`.\n\n- List item 1\n- List item 2\n\n", count: 100)
        
        measure {
            _ = converter.convertToRTF(markdown)
        }
    }
}
