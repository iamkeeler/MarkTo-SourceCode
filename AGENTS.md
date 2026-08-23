# AGENTS.md — Development & Contribution Guide

This document outlines architectural principles, coding standards, UX guidelines, security constraints, and engineering workflows for AI agents (and human contributors) working on **MarkTo**.

---

## 1. Project Overview & Philosophy

**MarkTo** is a lightweight, high-performance macOS utility designed to convert Markdown into Rich Text Format (RTF) with zero friction.

### Core Pillars
* **Friction-Free Speed**: Conversions must execute in under 50ms with instant clipboard availability (⌘R).
* **Native & Lightweight**: Minimal memory footprint (< 8MB), zero idle CPU, zero third-party dependencies.
* **Privacy by Design**: 100% offline, zero network access, zero analytics or telemetry.
* **Apple HIG First**: Feels like an Apple-designed system utility for macOS.

---

## 2. Tech Stack & Environment

| Component | Specification |
| :--- | :--- |
| **Platform** | macOS 13.0+ (Ventura, Sonoma, Sequoia) |
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI + AppKit Integration |
| **Concurrency** | Modern Swift Concurrency (`@MainActor`, `Sendable`, Strict Concurrency) |
| **System Frameworks** | `Combine`, `AppKit`, `ServiceManagement`, `UniformTypeIdentifiers` |
| **Dependencies** | **Zero external dependencies** (Pure Swift & Apple First-Party SDKs only) |

---

## 3. Project Structure & Directory Map

```
MarkConvert/
├── MarkTo/
│   ├── Models/                     # Pure business logic, AST parsing, RTF generation
│   │   ├── MarkdownConverter.swift  # Main Sendable interface for conversion
│   │   ├── MarkdownParser.swift     # Orchestrator for block & inline processing
│   │   ├── BlockProcessor.swift     # Headers, quotes, code blocks, horizontal rules
│   │   ├── InlineProcessor.swift    # Bold, italic, strikethrough, inline code, links
│   │   ├── ListProcessor.swift      # Ordered, unordered, nested, and task lists
│   │   ├── TableProcessor.swift     # Table AST parsing and native RTF table formatting
│   │   ├── ParsingContext.swift     # State tracker for line & block nesting
│   │   ├── FormattingPreferences.swift # Formatting tokens, fonts, and presets
│   │   └── ThemeManager.swift       # System, light, and dark appearance controller
│   ├── ViewModels/                 # @MainActor UI state & coordination
│   │   ├── MainViewModel.swift      # Text input debounce, async conversion, clipboard
│   │   └── FormattingViewModel.swift# Element selection, search filter, preset management
│   ├── Views/                      # Declarative SwiftUI views (Native Controls)
│   │   ├── ContentView.swift        # Main text editor, convert button, popover anchor notch
│   │   ├── SettingsView.swift       # App behavior, theme picker, font size, about
│   │   └── FormattingCustomizationView.swift # Detailed rich text styling panel
│   ├── Services/                   # AppKit & OS services
│   │   ├── AppSettings.swift        # AppPreferences singleton & UserDefaults sync
│   │   └── MenuBarManager.swift     # NSStatusItem, PopoverWindow, outside-click monitor
│   ├── Assets.xcassets/            # AppIcon, MenuBarIcon, Preview assets
│   ├── Info.plist                  # Dynamic bundle metadata & version strings
│   ├── MarkTo.entitlements         # Entitlements for Developer ID distribution
│   └── MarkTo-AppStore.entitlements# App Sandbox entitlements for Mac App Store
├── MarkToTests/                    # Comprehensive unit, UI, and E2E test suites
│   ├── AppPreferencesTests.swift   # Preferences persistence & version resolution
│   ├── UIViewModelTests.swift      # ViewModel state transitions & search filtering
│   ├── MarkToUITests.swift         # XCUIApplication UI automation tests
│   └── EndToEndPasteConversionTests.swift # Full clipboard paste & RTF verification
├── scripts/
│   └── run_test_suite.swift        # Automated CLI test runner (63+ test assertions)
├── .github/workflows/
│   └── release.yml                 # Automated CI/CD build, sign, notarize & DMG release
├── README.md                       # Public product documentation
└── AGENTS.md                       # Contributor & AI Agent development guidelines
```

---

## 4. Engineering & Architecture Principles

### 🧱 Model-View-ViewModel (MVVM)
* **Models** (`MarkTo/Models/`): Pure business logic, AST parsing, RTF generation, and state serialization. Models must have no dependencies on SwiftUI Views.
* **ViewModels** (`MarkTo/ViewModels/`): `@MainActor ObservableObject` classes managing UI state, debounce timers, async task coordination, and status alerts.
* **Views** (`MarkTo/Views/`): Declarative SwiftUI views displaying UI state and delegating actions to ViewModels.
* **Services** (`MarkTo/Services/`): Lifecycle management, `NSStatusBar` integration, `UserDefaults` persistence, and `SMAppService` login item registration.

### 🎯 DRY (Don't Repeat Yourself)
* Centralize markdown parsing algorithms across dedicated processors (`BlockProcessor`, `InlineProcessor`, `ListProcessor`, `TableProcessor`).
* Manage persistence keys centrally in `AppPreferences.Keys` and `FormattingPreferences`.
* Reuse formatting components and design tokens across both the standalone window and menu bar popover.

### ⚡ KISS (Keep It Simple, Stupid)
* Prioritize clean, readable, idiomatic Swift over complex abstractions, reflection, or unnecessary generic indirection.
* Avoid private compiler internal types (e.g., `_EnvironmentKeyWritingModifier`) in type checks or runtime assertions.
* Do not introduce third-party package managers (CocoaPods, Carthage, SPM packages) unless explicitly requested and approved.

---

## 5. UI & Native Controls Policy

### 🍏 Native Controls First
Always default to standard, first-party SwiftUI and AppKit components:
* Use standard `TextEditor`, `Button`, `Toggle`, `Picker`, `Slider`, `NavigationStack`, `Form`, `LabeledContent`, and `ProgressView`.
* Use native system materials (`.ultraThinMaterial`, `.regularMaterial`) and system visual effects for transparency and vibrancy.
* Use SF Symbols (`Image(systemName: ...)`) for consistent platform iconography.

### 📐 Custom Controls Rule (Strict Constraint)
**Only create custom UI controls or shapes when native SwiftUI/AppKit does not provide the capability.**
* *Approved Example*: `PopoverShape` in [`ContentView.swift`](file:///Users/iamkeeler/FileStorage/GitProjects/MarkConvert/MarkTo/Views/ContentView.swift) (required to render the upward-pointing anchor notch / uptick for the borderless menu bar dropdown window).
* *Approved Example*: `PopoverWindow` in [`MenuBarManager.swift`](file:///Users/iamkeeler/FileStorage/GitProjects/MarkConvert/MarkTo/Services/MenuBarManager.swift) (required for borderless `NSWindow` to become key and handle global click-to-dismiss).

### 📐 Window Sizing & Layout Specifications
* **Main Window**: `420 × 380 pt` (resizable content size).
* **Menu Bar Popover**: `420 × 410 pt` (floating borderless window positioned 4pt below status item with anchor uptick).
* **Settings Window**: `500 × 600 pt` (`.formStyle(.grouped)`).
* **Inline Status Banners**: Non-blocking pill banner with 4.0-second auto-dismiss and `.easeInOut(duration: 0.3)` transition.

### 🧭 Apple Human Interface Guidelines (HIG) & Usability
* **Recognition Over Recall**: Always provide direct, visible affordances (e.g. Settings gear icon in the menu bar popover header; ⌘, shortcut; tooltips with `.help()`).
* **Visual Anchor Connection**: Floating status bar windows must feature an anchor uptick pointing directly to the active `NSStatusItem`.
* **WCAG 2.1 AA Standards**:
  * **Contrast**: Text contrast ≥ 4.5:1 (normal text) and ≥ 3:1 (large text / icons).
  * **Click / Tap Target**: Primary actions must meet or exceed 24×24 pt (prefer 26–44 pt).
  * **Accessibility**: All interactive elements must supply explicit `.accessibilityLabel()` and VoiceOver descriptions.
  * **Keyboard Operability**: Full keyboard navigation support (⌘R to convert, ⌘, for settings, Esc/click-outside to dismiss).

---

## 6. Coding & Concurrency Standards

### Swift Concurrency & Actor Isolation
* Mark all UI classes, view models, and AppKit delegates with `@MainActor`:
  ```swift
  @MainActor
  final class MainViewModel: ObservableObject { ... }
  ```
* Mark backend parsers with `Sendable` (or `@unchecked Sendable` where thread-safety is guaranteed) to allow execution inside background tasks:
  ```swift
  final class MarkdownConverter: @unchecked Sendable { ... }
  ```
* **Safe Deinitialization (`deinit`)**:
  In Swift 5.9+, `deinit` on an actor-isolated class runs in a **nonisolated** context. Never call `@MainActor`-isolated instance methods inside `deinit`. Clean up timers and observers directly:
  ```swift
  deinit {
      if let monitor = globalClickMonitor {
          NSEvent.removeMonitor(monitor)
      }
      if let monitor = localClickMonitor {
          NSEvent.removeMonitor(monitor)
      }
  }
  ```

### Safe Initialization (No Premature Side-Effects)
* **Never** call mutating OS services (`SMAppService.mainApp.register/unregister`, `NSApplication.shared.setActivationPolicy`) during static initialization or inside `init()` of singleton objects.
* Initialize stored properties from `UserDefaults` in `init()`, and apply OS-level side effects inside `AppDelegate.applicationDidFinishLaunching(_:)` or on explicit user toggles.

### Dynamic Version Resolution
* **Never hardcode version or build strings in views.**
* Query versions dynamically from `Bundle.main.infoDictionary`:
  ```swift
  private var appVersion: String {
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
      let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
      return build.isEmpty ? version : "\(version) (\(build))"
  }
  ```
* Synchronize `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` across `project.pbxproj` and `Info.plist` on every release.

---

## 7. Security, Privacy & Entitlements

* **100% Offline**: No network calls, telemetry, analytics, or background internet access.
* **Entitlements**:
  * `MarkTo.entitlements`: Developer ID builds (allows hardened runtime and Apple notarization).
  * `MarkTo-AppStore.entitlements`: Mac App Store builds (`com.apple.security.app-sandbox` enabled).
* **Clipboard Usage**: Reads clipboard only when explicitly triggered or when `autoLoadClipboard` is enabled with valid markdown syntax.

---

## 8. Testing & Quality Gate

Every PR or agent modification must verify that all automated test suites pass with **0 failures and 0 warnings** before merging or releasing.

### Test Suites (`MarkToTests/` & `scripts/run_test_suite.swift`)
1. **Model & Parser Tests**: Validates headers, bold/italics, nested lists, code blocks, and markdown tables.
2. **AppPreferences Tests**: Validates defaults, `UserDefaults` persistence, and lifecycle policies.
3. **UI & ViewModel Tests**: Validates state transitions, search filtering, presets, and conversion guards.
4. **End-to-End Paste & Conversion Tests**: Simulates full clipboard input, RTF serialization, and attribute parsing in destination apps.

### Running the Test Suite
```bash
# Execute the comprehensive test runner
swiftc -module-cache-path ./scratch/module-cache MarkTo/Models/*.swift MarkTo/Services/AppSettings.swift MarkTo/ViewModels/*.swift scripts/run_test_suite.swift -o ./scratch/test_runner && ./scratch/test_runner
```
*(All 63+ tests must pass ✅ with exit code 0).*

---

## 9. Release & CI/CD Workflow

### GitHub Actions Release Pipeline (`.github/workflows/release.yml`)
* **Trigger**: Pushing to `release` branch or manual `workflow_dispatch`.
* **Automation Steps**:
  1. Compiles Release build via Xcode.
  2. Signs with Developer ID Application certificate (`--options runtime --timestamp`).
  3. Submits to Apple for Notarization (`xcrun notarytool`) and staples tickets.
  4. Packages `.dmg` disk image and computes `.sha256` checksum.
  5. Publishes a GitHub Release tagged `v<version>`.

---

## 10. Checklist for Agents & Contributors

Before submitting any changes:
- [ ] Code adheres to DRY and KISS principles with zero unnecessary dependencies.
- [ ] Native SwiftUI controls are used (custom shapes only when strictly necessary).
- [ ] No hardcoded versions or build numbers in views.
- [ ] No blocking side-effects in static/property initializers.
- [ ] Full dark mode, light mode, and system appearance verified.
- [ ] Keyboard shortcuts, tooltips, and accessibility labels added to all new interactive elements.
- [ ] `scripts/run_test_suite.swift` executed and 100% passing (63/63 ✅).
