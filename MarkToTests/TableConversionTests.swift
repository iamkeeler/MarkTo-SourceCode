import XCTest
@testable import MarkTo

final class TableConversionTests: XCTestCase {
    
    private var converter: MarkdownConverter!
    
    override func setUp() {
        super.setUp()
        converter = MarkdownConverter()
    }
    
    override func tearDown() {
        converter = nil
        super.tearDown()
    }
    
    func testSimpleTable() {
        let markdown = """
        | Name | Age | City |
        |------|-----|------|
        | John | 25 | NYC |
        | Jane | 30 | LA |
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("Name"), "Table header should be present")
            XCTAssertTrue(string.contains("Age"), "Table header should be present")
            XCTAssertTrue(string.contains("City"), "Table header should be present")
            XCTAssertTrue(string.contains("John"), "Table data should be present")
            XCTAssertTrue(string.contains("Jane"), "Table data should be present")
            XCTAssertTrue(string.contains("│"), "Table should have column separators")
            XCTAssertTrue(string.contains("─"), "Table should have row separators")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
    
    func testTableWithFormatting() {
        let markdown = """
        | **Feature** | *Status* | `Priority` |
        |-------------|----------|------------|
        | **Tables** | *In Progress* | `High` |
        | Lists | Complete | `Medium` |
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("Feature"), "Formatted header should be present")
            XCTAssertTrue(string.contains("Status"), "Formatted header should be present")
            XCTAssertTrue(string.contains("Priority"), "Formatted header should be present")
            XCTAssertTrue(string.contains("Tables"), "Formatted content should be present")
            XCTAssertTrue(string.contains("In Progress"), "Formatted content should be present")
            XCTAssertTrue(string.contains("High"), "Formatted content should be present")
            
            // Check for formatting attributes
            let fullRange = NSRange(location: 0, length: attributedString.length)
            var foundBold = false
            var foundItalic = false
            var foundCode = false
            
            attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
                if let font = attributes[.font] as? NSFont {
                    if font.fontDescriptor.symbolicTraits.contains(.bold) {
                        foundBold = true
                    }
                    if font.fontDescriptor.symbolicTraits.contains(.italic) {
                        foundItalic = true
                    }
                    if font.familyName?.contains("Mono") == true {
                        foundCode = true
                    }
                }
            }
            
            XCTAssertTrue(foundBold, "Table should preserve bold formatting")
            XCTAssertTrue(foundItalic, "Table should preserve italic formatting")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
    
    func testTableWithoutHeaderSeparator() {
        let markdown = """
        | Syntax | Description |
        | Header | Title |
        | Paragraph | Text |
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("Syntax"), "Table content should be present")
            XCTAssertTrue(string.contains("Description"), "Table content should be present")
            XCTAssertTrue(string.contains("Header"), "Table content should be present")
            XCTAssertTrue(string.contains("Title"), "Table content should be present")
            XCTAssertTrue(string.contains("Paragraph"), "Table content should be present")
            XCTAssertTrue(string.contains("Text"), "Table content should be present")
            XCTAssertTrue(string.contains("│"), "Table should have column separators")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
    
    func testTableWithLinks() {
        let markdown = """
        | Site | URL |
        |------|-----|
        | GitHub | [GitHub](https://github.com) |
        | Google | <https://google.com> |
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("Site"), "Table header should be present")
            XCTAssertTrue(string.contains("URL"), "Table header should be present")
            XCTAssertTrue(string.contains("GitHub"), "Link text should be present")
            XCTAssertTrue(string.contains("Google"), "Link text should be present")
            
            // Check for link attributes
            let fullRange = NSRange(location: 0, length: attributedString.length)
            var foundLink = false
            
            attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
                if attributes[.link] != nil {
                    foundLink = true
                }
            }
            
            XCTAssertTrue(foundLink, "Table should preserve link formatting")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
    
    func testMinimalTable() {
        let markdown = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("A"), "Table header should be present")
            XCTAssertTrue(string.contains("B"), "Table header should be present")
            XCTAssertTrue(string.contains("1"), "Table data should be present")
            XCTAssertTrue(string.contains("2"), "Table data should be present")
            XCTAssertTrue(string.contains("│"), "Table should have column separators")
            XCTAssertTrue(string.contains("─"), "Table should have row separators")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
    
    func testEmptyTable() {
        let markdown = """
        | | |
        |---|---|
        | | |
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("│"), "Table should have column separators even if empty")
            XCTAssertTrue(string.contains("─"), "Table should have row separators even if empty")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
    
    func testTableMixedWithOtherContent() {
        let markdown = """
        # Test Document
        
        This is a paragraph before the table.
        
        | Name | Age |
        |------|-----|
        | John | 25 |
        
        This is a paragraph after the table.
        
        - List item 1
        - List item 2
        """
        
        let result = converter.convertToRTF(markdown)
        
        switch result {
        case .success(let attributedString):
            let string = attributedString.string
            XCTAssertTrue(string.contains("Test Document"), "Header should be present")
            XCTAssertTrue(string.contains("This is a paragraph before"), "Content before table should be present")
            XCTAssertTrue(string.contains("Name"), "Table header should be present")
            XCTAssertTrue(string.contains("Age"), "Table header should be present")
            XCTAssertTrue(string.contains("John"), "Table data should be present")
            XCTAssertTrue(string.contains("This is a paragraph after"), "Content after table should be present")
            XCTAssertTrue(string.contains("List item 1"), "List content should be present")
            XCTAssertTrue(string.contains("│"), "Table should have column separators")
            XCTAssertTrue(string.contains("─"), "Table should have row separators")
        case .failure(let error):
            XCTFail("Table conversion failed: \(error)")
        }
    }
}
