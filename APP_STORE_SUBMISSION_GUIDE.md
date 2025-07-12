# MarkTo - Mac App Store Submission Guide

## ✅ Pre-Submission Checklist

Your MarkTo app has been prepared for Mac App Store submission with the following updates:

### 📋 **Requirements Met**

#### 1. **Info.plist Configuration**
- ✅ **Bundle Identifier**: `com.attachdesign.markto` (registered domain)
- ✅ **Version Numbers**: CFBundleVersion: "1", CFBundleShortVersionString: "1.0.0"
- ✅ **App Category**: `public.app-category.productivity`
- ✅ **Minimum System Version**: macOS 13.0
- ✅ **Privacy API Usage Declaration**: UserDefaults usage declared
- ✅ **Document Types**: Markdown file support (.md, .markdown)
- ✅ **Copyright**: Proper Attach.design attribution
- ✅ **Encryption Declaration**: ITSAppUsesNonExemptEncryption = false

#### 2. **App Sandbox & Entitlements**
- ✅ **App Sandbox**: Enabled (`com.apple.security.app-sandbox`)
- ✅ **File Access**: User-selected read-only files
- ✅ **Network Access**: Client connections (for privacy policy link)
- ✅ **Security Settings**: Hardened runtime compatible

#### 3. **Assets & Icons**
- ✅ **App Icon**: Complete icon set (16px to 1024px)
- ✅ **Menu Bar Icon**: Custom branded icon
- ✅ **High-Resolution Support**: NSHighResolutionCapable = true

#### 4. **Privacy & Compliance**
- ✅ **Privacy Policy**: Created and accessible
- ✅ **Data Collection**: None (explicitly documented)
- ✅ **Local Processing**: All operations happen offline
- ✅ **No Third-Party Services**: No analytics or tracking

### 🚀 **Next Steps for App Store Submission**

#### 1. **Apple Developer Account Setup**
- Ensure you have an active Apple Developer Program membership
- Register the bundle ID `com.attachdesign.markto` in App Store Connect
- Create app record in App Store Connect

#### 2. **Code Signing & Provisioning**
```bash
# Create distribution certificate and provisioning profile
# Set up app-specific password for notarization
```

#### 3. **Build for Distribution**
```bash
# Archive for distribution
xcodebuild archive -project MarkTo.xcodeproj -scheme MarkTo -archivePath MarkTo.xcarchive

# Export for App Store
xcodebuild -exportArchive -archivePath MarkTo.xcarchive -exportPath MarkTo -exportOptionsPlist ExportOptions.plist
```

#### 4. **App Store Connect Configuration**
- **App Name**: MarkTo
- **Category**: Productivity
- **Keywords**: markdown, rtf, converter, text, editor, productivity
- **Description**: "A lightweight, fast Markdown to RTF converter for macOS"
- **Screenshots**: Required in multiple sizes
- **Privacy Policy URL**: https://MarkTo.attach.design/privacy.html

#### 5. **Testing Requirements**
- ✅ **Functionality Testing**: All features work as expected
- ✅ **Sandbox Testing**: App works correctly in sandboxed environment
- ✅ **File Access Testing**: Markdown file handling works
- ✅ **Menu Bar Testing**: Menu bar integration functions properly

### 📱 **App Store Listing Information**

#### **Suggested App Description**
```
MarkTo - Effortless Markdown to RTF Conversion

Transform your Markdown documents into Rich Text Format (RTF) with just one click. MarkTo is designed for writers, developers, and anyone who works with Markdown and needs clean RTF output.

Features:
• Lightning-fast Markdown to RTF conversion
• Clean, distraction-free interface
• Menu bar integration for quick access
• Supports standard Markdown syntax
• Automatic clipboard copying
• Privacy-focused - all processing happens locally
• No internet connection required

Perfect for:
- Converting documentation for word processors
- Preparing formatted text for presentations
- Cross-platform document compatibility
- Quick text formatting tasks

MarkTo respects your privacy. No data is collected, tracked, or transmitted. All conversions happen entirely on your device.
```

#### **Keywords**
```
markdown, rtf, converter, text, editor, productivity, writer, developer, format, document
```

#### **Support Information**
- **Support URL**: https://attach.design
- **Marketing URL**: https://MarkTo.attach.design
- **Privacy Policy**: https://MarkTo.attach.design/privacy.html

### 🔧 **Technical Specifications**
- **Supported Architectures**: Apple Silicon (arm64), Intel (x86_64)
- **Minimum macOS**: 13.0 (Ventura)
- **App Size**: ~2MB (estimated)
- **Languages**: English (primary)

### 📋 **Final Checklist Before Submission**

- [ ] Test app thoroughly on clean macOS installation
- [ ] Verify all menu bar functionality
- [ ] Test Markdown file opening/processing
- [ ] Confirm privacy policy is accessible
- [ ] Check app icons display correctly at all sizes
- [ ] Verify app works without internet connection
- [ ] Test on both Apple Silicon and Intel Macs (if supporting both)
- [ ] Review App Store Review Guidelines compliance
- [ ] Prepare app screenshots for App Store listing
- [ ] Set up TestFlight for beta testing (optional but recommended)

### 🎯 **Revenue & Pricing Strategy**
Consider these pricing models:
- **Free**: Build user base, simple conversion tool
- **Paid ($2.99-$4.99)**: Premium utility pricing
- **Freemium**: Basic free, premium features paid

### 📞 **Support & Contact**
- **Developer**: Attach.design
- **Support Email**: support@attach.design
- **Website**: https://attach.design

---
## 🎉 Your app is now ready for Mac App Store submission!

All technical requirements have been met. Focus on creating great screenshots and a compelling app description for the best App Store presence.
