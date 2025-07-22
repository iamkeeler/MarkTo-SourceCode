import Foundation

// Test the enhanced markdown parsing logic
let testMarkdown = """
• **Large projects**
    - Takes a long time to analyze the entire project structure for a larger application
      **Problem:** Even smaller applications with less than 10,000 lines of code can take minutes to fully process
      **Solution:** Implement a file-based indexing system that can cache project analysis results and only re-analyze changed files

• **Documentation files**
    - Current implementation struggles with mixed content types within the same file
      **Problem:** Files containing both code snippets and natural language documentation are not parsed optimally
      **Solution:** Develop context-aware parsing that can distinguish between different content types within a single file

    - Large README files with complex formatting
        • Nested bullet points with multiple levels of indentation
        • Code blocks interspersed with explanatory text
            **Problem:** Multi-level lists lose their hierarchical structure during processing
            **Solution:** Implement a state-tracking parser that maintains list context across different indentation levels
"""

// Test indentation calculation
let testLines = [
    "• **Large projects**",                    // Expected: level 0
    "    - Takes a long time to analyze",      // Expected: level 1  
    "      **Problem:** Even smaller",         // Expected: level 1 (continuation)
    "        • Nested bullet points",          // Expected: level 2
    "            **Problem:** Multi-level"     // Expected: level 2 (continuation)
]

func calculateIndentLevel(_ line: String) -> Int {
    let leadingSpaces = line.prefix(while: { $0 == " " }).count
    
    if leadingSpaces <= 1 {
        return 0
    } else if leadingSpaces <= 5 {
        return 1
    } else {
        return 2
    }
}

func isListMarker(_ trimmedLine: String) -> Bool {
    return trimmedLine.hasPrefix("•") || 
           trimmedLine.hasPrefix("-") || 
           trimmedLine.hasPrefix("*") ||
           trimmedLine.hasPrefix("+") ||
           (trimmedLine.count >= 2 && 
            trimmedLine.first?.isNumber == true && 
            (trimmedLine.dropFirst().first == "." || trimmedLine.dropFirst().first == ")"))
}

print("Testing enhanced indentation calculation:")
for line in testLines {
    let level = calculateIndentLevel(line)
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    let isMarker = isListMarker(trimmed)
    print("Line: '\(line)'")
    print("  - Leading spaces: \(line.prefix(while: { $0 == " " }).count)")
    print("  - Calculated level: \(level)")
    print("  - Is list marker: \(isMarker)")
    print("")
}
