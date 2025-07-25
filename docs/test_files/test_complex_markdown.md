# Test Complex Markdown

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
