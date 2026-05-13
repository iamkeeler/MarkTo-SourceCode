#!/usr/bin/env ruby

file_path = 'MarkTo/Models/InlineProcessor.swift'
content = File.read(file_path)

# Ensure proper braces closing for processEmojis and processImages
content.gsub!(/                \/\/ If emoji not found in map, leave the original :emoji: syntax\n        \}\n    \}/, "                // If emoji not found in map, leave the original :emoji: syntax\n            }\n        }\n    }")

content.gsub!(/                \/\/ For RTF, represent images as styled text placeholders\n            attributedString/, "            // For RTF, represent images as styled text placeholders\n            attributedString")

File.write(file_path, content)
