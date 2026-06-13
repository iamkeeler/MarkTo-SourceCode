content = File.read('MarkTo/Views/FormattingCustomizationView.swift')
# Change page title
content.sub!(/Text\("Rich Text Formatting"\)\n\s*\.font\(\.title3\)/, "Text(\"Rich Text Formatting\")\n                    .font(.title2)")

# Change element header icon font
content.sub!(/Image\(systemName: iconForElement\(viewModel\.selectedElement\)\)\n\s*\.font\(\.title\)/, "Image(systemName: iconForElement(viewModel.selectedElement))\n                    .font(.title2)")

# Change element header title font
content.sub!(/Text\(viewModel\.selectedElement\.displayName\)\n\s*\.font\(\.title2\)/, "Text(viewModel.selectedElement.displayName)\n                        .font(.title3)")

File.write('MarkTo/Views/FormattingCustomizationView.swift', content)
