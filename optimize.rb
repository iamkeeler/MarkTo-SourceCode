#!/usr/bin/env ruby

file_path = 'MarkTo/Models/InlineProcessor.swift'
content = File.read(file_path)

# 1. Replace `let string = attributedString.string` with `let string = attributedString.string\n        let nsString = string as NSString`
content.gsub!(/let string = attributedString\.string\n\s*let range = NSRange\(location: 0, length: string\.count\)/, "let string = attributedString.string\n        let nsString = string as NSString\n        let range = NSRange(location: 0, length: nsString.length)")

content.gsub!(/let string = attributedString\.string\n\s*\/\/ Safety check/, "let string = attributedString.string\n        let nsString = string as NSString\n        \n        // Safety check")

# Fix for processAutoLinks, processBareURLs, processEmojis
content.gsub!(/let range = NSRange\(location: 0, length: string\.count\)/, "let range = NSRange(location: 0, length: nsString.length)")

# 2. Replace the Swift Range extraction with nsString.substring(with:)
# General case:
# if let contentSwiftRange = Range(contentRange, in: string) {
#     let content = String(string[contentSwiftRange])
content.gsub!(/if let contentSwiftRange = Range\(contentRange, in: string\) \{\n\s*let content = String\(string\[contentSwiftRange\]\)/, "let content = nsString.substring(with: contentRange)\n            if true {")

# Double case for Links:
# if let textSwiftRange = Range(textRange, in: string),
#    let urlSwiftRange = Range(urlRange, in: string) {
#     let linkText = String(string[textSwiftRange])
#     let linkURL = String(string[urlSwiftRange])
content.gsub!(/if let textSwiftRange = Range\(textRange, in: string\),\n\s*let urlSwiftRange = Range\(urlRange, in: string\) \{\n\s*let linkText = String\(string\[textSwiftRange\]\)\n\s*let linkURL = String\(string\[urlSwiftRange\]\)/, "let linkText = nsString.substring(with: textRange)\n            let linkURL = nsString.substring(with: urlRange)\n            if true {")

# URL case for AutoLinks and BareURLs:
# if let urlSwiftRange = Range(urlRange, in: string) {
#     let url = String(string[urlSwiftRange])
content.gsub!(/if let urlSwiftRange = Range\(urlRange, in: string\) \{\n\s*let url = String\(string\[urlSwiftRange\]\)/, "let url = nsString.substring(with: urlRange)\n            if true {")

# Emoji case:
# if let emojiNameSwiftRange = Range(emojiNameRange, in: string) {
#     let emojiName = String(string[emojiNameSwiftRange])
content.gsub!(/if let emojiNameSwiftRange = Range\(emojiNameRange, in: string\) \{\n\s*let emojiName = String\(string\[emojiNameSwiftRange\]\)/, "let emojiName = nsString.substring(with: emojiNameRange)\n            if true {")

# Image case:
# if let altSwiftRange = Range(altRange, in: string) {
#     let altText = String(string[altSwiftRange])
content.gsub!(/if let altSwiftRange = Range\(altRange, in: string\) \{\n\s*let altText = String\(string\[altSwiftRange\]\)/, "let altText = nsString.substring(with: altRange)\n            if true {")

File.write(file_path, content)
