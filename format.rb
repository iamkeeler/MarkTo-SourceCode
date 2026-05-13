#!/usr/bin/env ruby

file_path = 'MarkTo/Models/InlineProcessor.swift'
content = File.read(file_path)

content.gsub!(/                attributedString/, "            attributedString")
content.gsub!(/                    string:/, "                string:")
content.gsub!(/                    attributes:/, "                attributes:")
content.gsub!(/                        \.font:/, "                    .font:")
content.gsub!(/                        \.backgroundColor:/, "                    .backgroundColor:")
content.gsub!(/                        \.foregroundColor:/, "                    .foregroundColor:")
content.gsub!(/                        \.underlineStyle:/, "                    .underlineStyle:")
content.gsub!(/                        \.link:/, "                    .link:")
content.gsub!(/                        \.strikethroughStyle:/, "                    .strikethroughStyle:")
content.gsub!(/                \]\)/, "            ])")
content.gsub!(/                \)\)/, "            ))")

File.write(file_path, content)
