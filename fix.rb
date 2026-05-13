#!/usr/bin/env ruby

file_path = 'MarkTo/Models/InlineProcessor.swift'
content = File.read(file_path)

methods = [
  'processStrikethrough',
  'processBoldPattern',
  'processItalicPattern',
  'processCode',
  'processAutoLinks',
  'processBareURLs',
  'processEmojis',
  'processImages'
]

methods.each do |method_name|
  # Replace 'let string = attributedString.string'
  # with 'let nsString = attributedString.string as NSString'
end
