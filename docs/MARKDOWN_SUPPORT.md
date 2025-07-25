# MarkTo - Comprehensive Markdown Support

## Overview
MarkTo's enhanced Markdown parser now supports a comprehensive range of Markdown formatting possibilities, ensuring accurate conversion to Rich Text Format (RTF).

## Supported Markdown Features

### 📝 Headers
- **All 6 levels**: `# ## ### #### ##### ######`
- **Font sizes**: 24pt, 20pt, 18pt, 16pt, 14pt, 13pt respectively
- **Inline formatting preserved**: Headers can contain bold, italic, code, etc.
- **Auto-detection**: Uses regex pattern matching for reliability

### ✨ Inline Formatting
- **Bold**: `**text**` or `__text__`
- **Italic**: `*text*` or `_text_`
- **Code**: `` `inline code` ``
- **Strikethrough**: `~~text~~`
- **Combined formatting**: Supports nested inline styles

### 📋 Lists
- **Unordered lists**: `- * +` (with alternating bullet styles)
- **Ordered lists**: `1. 2. 3.` etc.
- **Nested lists**: Multiple indentation levels supported
- **Task lists**: `- [ ]` and `- [x]` with checkboxes
- **Smart indentation**: Automatic level detection

### 🔗 Links & Images
- **Standard links**: `[text](url)`
- **Auto-links**: `<http://example.com>` and `<email@domain.com>`
- **Images**: `![alt text](src)` (rendered as `[Image: alt text]` in RTF)
- **Link styling**: Blue color with underline

### 📦 Block Elements
- **Blockquotes**: `> quoted text` with left bar indicator
- **Code blocks**: `` ``` `` with language specification support
- **Horizontal rules**: `---`, `***`, or `___`
- **Definition lists**: `: definition` with indentation

### 📊 Tables
- **Pipe tables**: `| header | header |`
- **Header detection**: Bold formatting for first row
- **Separator handling**: Skips alignment rows (`---|---`)
- **Cell formatting**: Preserves inline markdown within cells

### 🔄 Advanced Features
- **Escape sequences**: Proper handling of markdown characters
- **Whitespace preservation**: Maintains original spacing
- **Error recovery**: Graceful fallback for malformed syntax
- **Performance optimized**: Efficient scanning and parsing

## Implementation Details

### Parser Architecture
- **Line-by-line processing**: Each line analyzed independently
- **State tracking**: Code blocks, list nesting, table contexts
- **Regex patterns**: Robust pattern matching for all elements
- **Scanner-based**: Efficient character-by-character parsing for inline elements

### RTF Conversion
- **NSAttributedString**: Native macOS text formatting
- **Font management**: System fonts with proper sizing
- **Color support**: Semantic colors for links, quotes, etc.
- **Background colors**: Code highlighting with system colors

### Quality Assurance
- ✅ **No third-party dependencies**: Pure Apple frameworks
- ✅ **Error handling**: Comprehensive error recovery
- ✅ **Performance**: Optimized for typical document sizes
- ✅ **Compatibility**: Standard Markdown specification compliance

## Missing/Intentionally Excluded Features

### Markdown Extensions (CommonMark+)
- **Footnotes**: Not commonly used in RTF contexts
- **Math expressions**: LaTeX not supported in RTF
- **Mermaid diagrams**: Visual elements beyond RTF scope
- **Custom containers**: Advanced formatting not needed

### Advanced Table Features
- **Column alignment**: RTF limitations
- **Complex cell spanning**: RTF complexity
- **Table styling**: Beyond basic formatting

## Testing Coverage

### Basic Elements ✅
- Headers (all levels)
- Paragraphs and line breaks
- Bold, italic, code formatting
- Lists (ordered, unordered, nested)

### Advanced Elements ✅
- Links and auto-links
- Images (placeholder text)
- Blockquotes
- Code blocks
- Horizontal rules
- Tables
- Task lists
- Strikethrough

### Edge Cases ✅
- Nested formatting
- Escaped characters
- Mixed list types
- Malformed syntax recovery
- Empty elements
- Whitespace handling

## Performance Characteristics

- **Typical processing time**: <100ms for standard documents
- **Memory usage**: Minimal overhead
- **Scalability**: Linear performance with document size
- **Efficiency**: Single-pass parsing where possible

## Future Enhancements

### Potential Additions
1. **Syntax highlighting**: Language-specific code formatting
2. **Custom styles**: User-configurable fonts and colors
3. **Export options**: Additional format support
4. **Live preview**: Real-time conversion display

### Optimization Opportunities
1. **Caching**: Repeated conversion optimization
2. **Streaming**: Large document handling
3. **Parallel processing**: Multi-threaded parsing
4. **Memory optimization**: Reduced allocation overhead

---

**Built with**: Pure Swift + AppKit + Foundation
**Compatibility**: macOS 13.0+
**License**: Proprietary (Attach.design)
