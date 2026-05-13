#!/usr/bin/env ruby

file_path = 'MarkTo/Models/InlineProcessor.swift'
content = File.read(file_path)

# Clean up empty if true
content.gsub!(/if true \{\s*/, "")
content.gsub!(/\s*\}\n        \}\n    \}/, "\n        }\n    }")
content.gsub!(/\s*\}\n                \/\/ If emoji not found/, "\n                // If emoji not found")
content.gsub!(/\s*\}\n        \}\n\n    \/\//, "\n        }\n\n    //")

File.write(file_path, content)
