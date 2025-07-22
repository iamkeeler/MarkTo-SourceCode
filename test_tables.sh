#!/bin/bash

# Manual test script for table conversion
# This script will test the table conversion functionality

echo "🧪 Testing Table Conversion in MarkTo"
echo "======================================="

echo ""
echo "📝 Test Data:"
echo "| Name | Age | City |"
echo "|------|-----|------|"
echo "| John | 25 | NYC |"
echo "| Jane | 30 | LA |"
echo ""

echo "🔍 To manually test:"
echo "1. Launch MarkTo app"
echo "2. Copy the table markdown above"
echo "3. Paste it into the app"
echo "4. Click 'Convert to RTF'"
echo "5. Paste the result into a rich text editor (like TextEdit)"
echo "6. Verify the table is properly formatted with:"
echo "   - Proper column separation (│)"
echo "   - Header row in bold"
echo "   - Row separators (─)"
echo "   - Aligned content"
echo ""

echo "✅ Expected result should show:"
echo "Name │ Age │ City"
echo "─────┼─────┼─────"
echo "John │ 25  │ NYC"
echo "Jane │ 30  │ LA"
echo ""

echo "🚀 Run this test with multiple table formats from table_test.md"
echo "📄 Test file location: $(pwd)/table_test.md"
