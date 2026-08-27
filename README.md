# MarkTo

<div align="center">
  <img src="MarkTo/Assets.xcassets/AppIcon.appiconset/MarkTo_icn_V2_256.png" alt="MarkTo app icon" width="128" height="128">

  **Convert Markdown to rich text on your Mac. Paste text or drop a file.**

  [![macOS 13+](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
  [![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
  [![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](License/LICENSE)
  [![GitHub Release](https://img.shields.io/github/v/release/iamkeeler/MarkTo-SourceCode)](https://github.com/iamkeeler/MarkTo-SourceCode/releases/latest)
</div>

MarkTo converts Markdown into Rich Text Format (RTF). Copy the result into a rich-text app, or convert a Markdown file directly into an RTF file beside the original.

MarkTo runs locally. It does not send your documents to a server or include analytics or telemetry.

## Download

- [Mac App Store](https://apps.apple.com/us/app/markto/id6748564673?mt=12)
- [Latest GitHub release](https://github.com/iamkeeler/MarkTo-SourceCode/releases/latest) — signed and notarized DMG

MarkTo requires macOS 13 Ventura or later.

## What MarkTo does

- Converts Markdown text to RTF and copies both rich text and plain text to the clipboard.
- Converts `.md` and `.markdown` files into sibling `.rtf` files.
- Preserves existing exports by naming the next file `Document 2.rtf`, `Document 3.rtf`, and so on.
- Works in a standard window or from the menu bar.
- Formats headings, paragraphs, links, bare URLs, bold, italics, strikethrough, and inline code.
- Handles fenced code blocks, block quotes, and horizontal rules.
- Converts nested ordered, unordered, and task lists, plus pipe-delimited tables.
- Lets you customize fonts, sizes, spacing, and styles for Markdown elements.
- Supports light, dark, and system appearance.
- Can start at login, hide its Dock icon, and keep its main window hidden at startup.

## Use MarkTo

### Convert text

1. Open MarkTo.
2. Type or paste Markdown into the editor.
3. Select **Convert to RTF**, or press **Command-R**.
4. Paste the result into a rich-text app.

### Convert a file

Use any of these methods:

- Drop a `.md` or `.markdown` file into the main window.
- Drop a file into the menu-bar popover.
- Open a Markdown file with MarkTo from Finder.
- Drop a Markdown file onto the MarkTo app or Dock icon.
- Right-click the menu-bar icon and select **Convert Markdown File…**.

MarkTo creates the RTF file in the same folder as the Markdown file. It never overwrites an existing export.

### Use the menu bar

- Left-click the MarkTo menu-bar icon to open or close the conversion popover.
- Right-click the icon to convert files, open the main window, open Settings, or quit.

## Privacy and file access

Markdown conversion happens on your Mac. MarkTo contains no analytics or telemetry and does not upload document content.

MarkTo accesses only the data needed for the action you choose:

- **Clipboard:** MarkTo does not read the clipboard when it opens. It writes converted rich text and plain text only after you select Convert.
- **Markdown files:** MarkTo reads files that you open, select, or drop into the app. File conversion writes an RTF file beside the source document.
- **Settings:** MarkTo stores app and formatting preferences in local macOS preferences.

Links in Settings open their websites in your browser.

## Build from source

You need macOS 13 or later, Xcode 15 or later, and Swift 5.9 or later.

```bash
git clone https://github.com/iamkeeler/MarkTo-SourceCode.git
cd MarkTo-SourceCode
open MarkTo.xcodeproj
```

Build the direct-download version from the command line:

```bash
xcodebuild \
  -project MarkTo.xcodeproj \
  -scheme MarkTo \
  -configuration Release \
  build
```

Build the sandboxed Mac App Store version:

```bash
xcodebuild \
  -project MarkTo.xcodeproj \
  -scheme MarkTo-AppStore \
  -configuration AppStore \
  -destination "generic/platform=macOS" \
  archive
```

The project uses SwiftUI, AppKit, Combine, and ServiceManagement. It has no third-party runtime dependencies.

## Contribute

Bug reports, fixes, tests, documentation, and UI improvements are welcome. Read the [contribution guide](docs/CONTRIBUTING.md) before opening a pull request.

- Developer: Gary Keeler
- GitHub: [@iamkeeler](https://github.com/iamkeeler)
- Website: [attach.design](https://attach.design)
- Email: [gary@attach.design](mailto:gary@attach.design)

## License

MarkTo uses the [Creative Commons Attribution-NonCommercial 4.0 International License](License/LICENSE). You may share and adapt the project with attribution for noncommercial purposes. Contact [gary@attach.design](mailto:gary@attach.design) for commercial licensing.
