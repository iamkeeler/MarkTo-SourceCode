# MarkTo

<div align="center">
  <img src="MarkTo/Assets.xcassets/AppIcon.appiconset/MarkTo_icn_V2_256.png" alt="MarkTo Icon" width="128" height="128">
  
  **A lightweight, native macOS application for converting Markdown to Rich Text Format (RTF)**
  
  [![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
  [![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
  [![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](License/LICENSE)
  [![GitHub Release](https://img.shields.io/github/v/release/iamkeeler/MarkTo-SourceCode?include_prereleases)](https://github.com/iamkeeler/MarkTo-SourceCode/releases)
  [![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)
  
</div>

## About MarkTo

MarkTo is designed for users who frequently work with Markdown and need a quick, reliable way to convert it to Rich Text Format (RTF). Whether you're preparing content for applications that don't support Markdown or need to maintain formatting when copying text, MarkTo provides a seamless, native macOS experience.

## ✨ Features

### ⚡ **Core Functionality**
- **Instant Conversion**: Convert Markdown to RTF with a single click or keyboard shortcut (⌘R)
- **Clipboard Integration**: Automatically copies converted RTF to clipboard for immediate use
- **Formatting Preview**: Preview output styles while customizing Markdown elements
- **Menu Bar Access**: Quick access from menu bar with optional Dock icon hiding
- **Hide on Startup**: Option to launch silently in the background into the menu bar upon login/boot

### 📝 **Markdown Support**
- **Headers**: All levels (`# H1` through `###### H6`)
- **Text Formatting**: Bold (`**text**`), Italic (`*text*`), Inline Code (`` `code` ``), Strikethrough (`~~text~~`)
- **Tables**: Pipe-delimited Markdown tables with headers and portable RTF formatting
- **Lists**: Nested unordered (`-`, `*`, `+`) and ordered (`1.`, `2.`, etc.)
- **Code Blocks**: Fenced code blocks with preserved monospaced formatting
- **Paragraphs & Links**: Proper paragraph spacing, hyperlinks, and bare URL auto-linking

### ⚙️ **Customization**
- **Rich Text Formatting**: Customize fonts, sizes, and styles for each Markdown element
- **Font Size Control**: Adjustable editor font size (10-24pt)
- **Character Count**: Optional character counter
- **Dual Interface**: Choose between menu bar dropdown or standalone window
- **App Behavior**: Configure start at login, hide dock icon, and hide window on startup

### 🎨 **User Experience**
- **Native macOS Design**: Follows macOS Human Interface Guidelines with system appearance support (Light/Dark/System)
- **Accessibility**: Full VoiceOver support and keyboard navigation
- **Performance**: Lightning-fast conversion (< 50ms for typical documents)
- **Memory Efficient**: < 8MB footprint, < 0.1% CPU when idle

## 🔒 Privacy

MarkTo is built with privacy as a core principle:

- **No Network Access**: All processing happens locally on your Mac
- **No Data Collection**: We don't collect, store, or transmit any of your data
- **No Analytics**: No tracking, telemetry, or usage analytics
- **Open Source**: Code is publicly available for review and transparency

Your Markdown content never leaves your device. MarkTo only accesses:
- **Clipboard**: To copy converted RTF (with your explicit action)
- **User Preferences**: To save your settings locally

## 📱 App Store & GitHub Releases

- **Mac App Store**: Available on the [Mac App Store](https://apps.apple.com/app/markto/id6741703212)
- **GitHub Releases**: Download pre-built, signed, and notarized DMG disk images directly from [GitHub Releases](https://github.com/iamkeeler/MarkTo-SourceCode/releases).

## 🗺 Roadmap

### Current Version (1.0.4)
- ✅ Core Markdown to RTF conversion
- ✅ Full Markdown table support with native RTF table formatting
- ✅ Menu bar integration & Hide Dock Icon mode
- ✅ Hide window on startup option
- ✅ Customizable formatting per markdown element
- ✅ Dynamic versioning & preference sync
- ✅ Privacy-focused design

### Planned Features
- 🔄 Export to additional formats (HTML, PDF, Word)
- 📊 Extended Markdown syntax enhancements (footnotes, definition lists)

## 🚀 Usage

### Quick Start
1. Launch MarkTo from Applications or menu bar
2. Type or paste your Markdown content
3. Click "Convert to RTF & Copy" or press ⌘R
4. Paste into any RTF-compatible application (Pages, Word, etc.)

### Menu Bar Mode
- Click the MarkTo icon in your menu bar for quick access
- Right-click for settings and preferences
- Perfect for quick conversions without opening a full window

### Formatting Customization
- Access **Settings** → **Rich Text Formatting**
- Customize fonts, sizes, and styles for each Markdown element
- Preview changes in real-time

## 🏗 Architecture

MarkTo follows modern iOS/macOS development best practices:

- **MVVM Pattern**: Clean separation between UI and business logic
- **SwiftUI**: Native, declarative user interface
- **Combine Framework**: Reactive programming for smooth performance
- **AppKit Integration**: Native macOS menu bar functionality
- **Accessibility First**: Built-in support for VoiceOver and assistive technologies

## 📊 Performance

- **Conversion Speed**: < 50ms for typical documents
- **Memory Usage**: < 8MB footprint
- **CPU Usage**: < 0.1% when idle
- **Battery Impact**: Minimal - designed for all-day use

## 🔧 Building from Source

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build Instructions
```bash
# Clone the repository
git clone https://github.com/iamkeeler/MarkTo-SourceCode.git
cd MarkTo-SourceCode

# Open in Xcode
open MarkTo.xcodeproj

# Build and run (⌘R in Xcode)
# Or from command line:
xcodebuild -project MarkTo.xcodeproj -scheme MarkTo -configuration Release build
```

### Distribution Builds

- Use the `MarkTo` scheme with the `Release` configuration for the Developer ID-signed, notarized direct-download build.
- Use the `MarkTo-AppStore` scheme to archive for App Store Connect. Its `AppStore` configuration enables App Sandbox and signs with `MarkTo-AppStore.entitlements`.

```bash
xcodebuild \
  -project MarkTo.xcodeproj \
  -scheme MarkTo-AppStore \
  -configuration AppStore \
  -destination "generic/platform=macOS" \
  archive
```

## 🤝 Contributing

We welcome contributions! MarkTo is open source and we'd love your help making it better.

Please read our [Contributing Guide](CONTRIBUTING.md) for detailed information about the development process, code style, and how to submit pull requests.

### Quick Start for Contributors
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Types of Contributions
- 🐛 Bug fixes
- ✨ New features
- 📚 Documentation improvements
- 🎨 UI/UX enhancements
- 🧪 Tests
- 🌐 Internationalization

### Developer Contact
- **Developer**: Gary Keeler
- **GitHub**: [@iamkeeler](https://github.com/iamkeeler)
- **Website**: [attach.design](https://attach.design)
- **Email**: [gary@attach.design](mailto:gary@attach.design)

## 📄 License

MarkTo is released under the Creative Commons Attribution-NonCommercial 4.0 International License. See [LICENSE](License/LICENSE) for details.

This means you are free to:
- ✅ **Use** the software for personal and non-commercial purposes
- ✅ **Modify** and adapt the code for your needs
- ✅ **Share** the software and your modifications
- ❌ **Sell** or use commercially without permission

For commercial licensing, please contact [gary@attach.design](mailto:gary@attach.design).

This project welcomes contributions from the community!
