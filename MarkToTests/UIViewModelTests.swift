import XCTest
import Combine
import SwiftUI
@testable import MarkTo

@MainActor
final class UIViewModelTests: XCTestCase {
    private func makeFormattingViewModel() -> FormattingViewModel {
        let suiteName = "com.attachdesign.markto.ui-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return FormattingViewModel(
            formattingPreferences: FormattingPreferences(userDefaults: defaults)
        )
    }

    // MARK: - MainViewModel UI State & Action Tests

    func testMainViewModelInitialState() {
        let vm = MainViewModel()

        XCTAssertEqual(vm.markdownText, "", "Initial markdown text should be empty")
        XCTAssertFalse(vm.isConverting, "isConverting should be false initially")
        XCTAssertEqual(vm.statusMessage, "", "Status message should be empty initially")
        XCTAssertFalse(vm.isSuccess, "isSuccess should be false initially")
    }

    func testMainViewModelClearText() {
        let vm = MainViewModel()
        vm.markdownText = "# Test Heading"
        vm.clearText()

        XCTAssertEqual(vm.markdownText, "", "clearText should empty the markdown text")
        XCTAssertEqual(vm.statusMessage, "", "clearText should clear status message")
    }

    func testMainViewModelEmptyConversionGuard() {
        let vm = MainViewModel()
        vm.markdownText = "   \n  "
        vm.convertToRTF()

        XCTAssertFalse(vm.isConverting, "isConverting should remain false for empty text")
        XCTAssertEqual(vm.statusMessage, "Please enter some markdown text", "Should warn about empty text")
        XCTAssertFalse(vm.isSuccess, "isSuccess should be false for empty input error")
    }

    // MARK: - FormattingViewModel UI State & Action Tests

    func testFormattingViewModelInitialState() {
        let vm = makeFormattingViewModel()

        XCTAssertEqual(vm.selectedElement, .body, "Default selected element should be body")
        XCTAssertEqual(vm.selectedCategory, .text, "Default selected category should be text")
        XCTAssertEqual(vm.searchText, "", "Initial search query should be empty")
        XCTAssertFalse(vm.showResetAlert, "showResetAlert should default to false")
        XCTAssertNil(vm.elementToReset, "elementToReset should default to nil")
    }

    func testFormattingViewModelCategoryAndElementSelection() {
        let vm = makeFormattingViewModel()

        vm.selectElement(.header1)
        XCTAssertEqual(vm.selectedElement, .header1)
        XCTAssertEqual(vm.selectedCategory, .headers, "Selecting H1 should update category to headers")

        vm.selectElement(.code)
        XCTAssertEqual(vm.selectedElement, .code)
        XCTAssertEqual(vm.selectedCategory, .inline, "Selecting code should update category to inline")

        vm.selectElement(.blockquote)
        XCTAssertEqual(vm.selectedElement, .blockquote)
        XCTAssertEqual(vm.selectedCategory, .blocks, "Selecting blockquote should update category to blocks")
    }

    func testFormattingViewModelSearchFilter() {
        let vm = makeFormattingViewModel()
        vm.selectedCategory = .headers

        // No search filter: shows all headers
        let allHeaders = vm.filteredElements
        XCTAssertEqual(allHeaders.count, 6, "Should show H1 through H6 in headers category")

        // Search filter matching H1
        vm.searchText = "Header 1"
        let filtered = vm.filteredElements
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first, .header1)

        // Search filter with no match in category
        vm.searchText = "NonExistentElement"
        XCTAssertTrue(vm.filteredElements.isEmpty)
    }

    func testFormattingViewModelPropertyUpdates() {
        let vm = makeFormattingViewModel()
        vm.selectElement(.body)

        // Font size update
        vm.updateFontSize(18.0)
        XCTAssertEqual(vm.currentFormatting.fontSize, 18.0)

        // Font weight update
        vm.updateFontWeight(.bold)
        XCTAssertEqual(vm.currentFormatting.fontWeight, .bold)

        // Line spacing update
        vm.updateLineSpacing(1.5)
        XCTAssertEqual(vm.currentFormatting.lineSpacing, 1.5)

        // Character spacing update
        vm.updateCharacterSpacing(0.5)
        XCTAssertEqual(vm.currentFormatting.characterSpacing, 0.5)
    }

    func testFormattingViewModelPresets() {
        let vm = makeFormattingViewModel()
        vm.selectElement(.body)

        // Compact preset
        vm.applyPreset(.compact)
        XCTAssertEqual(vm.currentFormatting.lineSpacing, 1.0)

        // Spaced preset
        vm.applyPreset(.spacious)
        XCTAssertEqual(vm.currentFormatting.lineSpacing, 1.6)
    }

    func testFormattingViewModelResetActions() {
        let vm = makeFormattingViewModel()
        vm.selectElement(.body)

        // Modify formatting
        vm.updateFontSize(22.0)
        XCTAssertEqual(vm.currentFormatting.fontSize, 22.0)

        // Trigger single element reset
        vm.resetCurrentElement()
        XCTAssertTrue(vm.showResetAlert)
        XCTAssertEqual(vm.elementToReset, .body)

        // Confirm reset
        vm.confirmResetElement()
        XCTAssertNil(vm.elementToReset)
        XCTAssertEqual(vm.currentFormatting.fontSize, 14.0, "Body font size should reset to default (14pt)")

        // Reset all
        vm.updateFontSize(20.0)
        vm.resetAllFormatting()
        XCTAssertEqual(vm.currentFormatting.fontSize, 14.0, "Reset all should restore default body font size")
    }

    func testFormattingViewModelExportSettings() {
        let vm = makeFormattingViewModel()
        let export = vm.exportFormatting()

        XCTAssertTrue(export.contains("MarkTo Formatting Settings"), "Export should have title header")
        XCTAssertTrue(export.contains("Body Text:"), "Export should include body text element")
        XCTAssertTrue(export.contains("Header 1:"), "Export should include header 1 element")
        XCTAssertTrue(export.contains("Font Size:"), "Export should include font sizes")
    }

    func testFormattingViewModelPreviewAttributedString() {
        let vm = makeFormattingViewModel()
        let previewAttr = vm.getPreviewAttributedString(for: .header1)

        XCTAssertFalse(previewAttr.string.isEmpty, "Preview string should not be empty")
        XCTAssertEqual(previewAttr.string, MarkdownElement.header1.exampleText)
    }
}
