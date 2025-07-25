# Contributing to MarkTo

Thank you for your interest in contributing to MarkTo! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to maintain a welcoming and inclusive environment for everyone. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- Git
- Basic knowledge of Swift and SwiftUI

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   # Go to https://github.com/iamkeeler/MarkTo-SourceCode and click "Fork"
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/MarkTo-SourceCode.git
   cd MarkTo-SourceCode
   ```

3. **Open in Xcode**
   ```bash
   open MarkTo.xcodeproj
   ```

4. **Build and run**
   - Press ⌘R in Xcode to build and run the app
   - Ensure everything works correctly before making changes

## Making Contributions

### Types of Contributions We Welcome

- **Bug fixes** - Help us squash bugs!
- **Feature improvements** - Enhance existing functionality
- **New features** - Add new capabilities (please discuss first)
- **Documentation** - Improve README, code comments, or create guides
- **Testing** - Add unit tests or integration tests
- **Performance optimizations** - Make MarkTo faster and more efficient
- **UI/UX improvements** - Enhance the user experience
- **Accessibility** - Improve support for assistive technologies

### Before You Start

For significant changes:
1. **Open an issue** to discuss your idea
2. **Get feedback** from maintainers and community
3. **Plan your approach** before coding

For small fixes:
- Feel free to submit a pull request directly

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation if needed

3. **Test thoroughly**
   - Test your changes manually
   - Ensure existing functionality still works
   - Test on different macOS versions if possible

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add brief description of your changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Submit a Pull Request**
   - Go to GitHub and create a pull request
   - Provide a clear description of your changes
   - Reference any related issues

## Code Guidelines

### Swift Style Guide

- Follow Swift's official style guide
- Use meaningful variable and function names
- Prefer explicit types when it improves readability
- Use SwiftUI best practices

### Code Organization

```
MarkTo/
├── Models/          # Data models and business logic
├── Views/           # SwiftUI views
├── ViewModels/      # MVVM view models
├── Services/        # App services (MenuBar, Settings, etc.)
└── Assets.xcassets/ # Images and assets
```

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally

Examples:
- `Fix markdown parsing for nested lists`
- `Add keyboard shortcut for convert action`
- `Update README with installation instructions`

## Testing

### Manual Testing Checklist

- [ ] App launches successfully
- [ ] Menu bar icon appears and functions
- [ ] Markdown conversion works correctly
- [ ] RTF output is properly formatted
- [ ] Clipboard integration works
- [ ] Settings are saved and loaded
- [ ] No memory leaks or performance issues

### Areas That Need Testing

- Different Markdown syntax combinations
- Edge cases (empty input, very large documents)
- macOS version compatibility
- Memory usage with large documents
- Menu bar behavior across different system configurations

## Documentation

When adding new features:
- Update relevant code comments
- Add inline documentation for public APIs
- Update README.md if user-facing changes
- Consider adding to the app's help system

## Reporting Issues

### Before Reporting
- Check if the issue already exists
- Try to reproduce the issue
- Gather relevant information

### Issue Template
Please include:
- **Description**: Clear description of the issue
- **Steps to Reproduce**: Numbered list of steps
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: macOS version, app version
- **Screenshots**: If applicable

## Feature Requests

When requesting features:
- Explain the use case and problem it solves
- Provide examples of how it would work
- Consider implementation complexity
- Be open to alternative solutions

## Questions and Help

- **Discussions**: Use GitHub Discussions for questions
- **Email**: gary@attach.design for private inquiries
- **Issues**: Use GitHub Issues for bugs and feature requests

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- App credits (for significant contributions)
- Release notes (when applicable)

## License

By contributing to MarkTo, you agree that your contributions will be licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.

### License Summary
- ✅ **Personal Use**: Free to use and modify for personal projects
- ✅ **Educational Use**: Perfect for learning and academic purposes  
- ✅ **Open Source Projects**: Can be used in other non-commercial open source projects
- ❌ **Commercial Use**: Requires separate commercial licensing
- 📧 **Commercial Inquiries**: Contact gary@attach.design for commercial licensing

This license ensures the project remains freely available for the community while protecting the commercial interests of the original creator.

---

Thank you for contributing to MarkTo! 🚀
