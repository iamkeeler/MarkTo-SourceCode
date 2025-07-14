# MarkTo

<div align="center">
  <img src="MarkTo/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="MarkTo Icon" width="128" height="128">
  
  **A lightweight, native macOS application for converting Markdown to Rich Text Format (RTF)**
  
  [![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
  [![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  
  [Download from App Store](#app-store) • [Features](#features) • [Privacy](#privacy) • [Support](#support)
</div>

## About MarkTo

MarkTo is designed for users who frequently work with Markdown and need a quick, reliable way to convert it to Rich Text Format (RTF). Whether you're preparing content for applications that don't support Markdown or need to maintain formatting when copying text, MarkTo provides a seamless, native macOS experience.

## ✨ Features

### � **Core Functionality**
- **Instant Conversion**: Convert Markdown to RTF with a single click or keyboard shortcut (⌘R)
- **Clipboard Integration**: Automatically copies converted RTF to clipboard for immediate use
- **Real-time Preview**: See your formatting as you type with syntax highlighting
- **Menu Bar Access**: Quick access from menu bar without cluttering your dock

### 📝 **Markdown Support**
- **Headers**: All levels (`# H1` through `#### H4`)
- **Text Formatting**: Bold (`**text**`), Italic (`*text*`), Inline Code (`` `code` ``)
- **Lists**: Unordered (`-`, `*`, `+`) and ordered (`1.`, `2.`, etc.)
- **Code Blocks**: Fenced code blocks with ``` syntax
- **Paragraphs**: Proper paragraph spacing and formatting

### ⚙️ **Customization**
- **Rich Text Formatting**: Customize fonts, sizes, and styles for each Markdown element
- **Font Size Control**: Adjustable editor font size (10-24pt)
- **Character Count**: Optional character counter
- **Dual Interface**: Choose between menu bar dropdown or standalone window

### 🎨 **User Experience**
- **Native macOS Design**: Follows macOS Human Interface Guidelines
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

## 📱 App Store

*Coming Soon to the Mac App Store*

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

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Developer Contact
- **Developer**: Gary Keeler
- **GitHub**: [@iamkeeler](https://github.com/iamkeeler)
- **Website**: [attachdesign.com](https://markto.attach.design)
- **Email**: [Support Email](mailto:gary@attach.design)

## 📄 License

MarkTo is released under the MIT License. See [LICENSE](LICENSE) for details.

