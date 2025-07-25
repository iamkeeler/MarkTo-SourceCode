# Phase 2 Markdown Compliance Test

This file tests the enhancements made in Phase 2: Enhanced Markdown Compliance.

## Escape Sequences
These characters should display literally: \* \_ \` \~ \#

Backslash at end of line: \
Next line should start here.

## Bare URL Detection
Check https://github.com for bare URL detection
Also test http://example.com and ftp://files.example.org

Mixed text with https://www.apple.com in the middle of a sentence.

## Line Breaks (Double Space)
This line ends with two spaces.  
This should be on a new line.

Normal line break.
This should continue on same paragraph.

## Emoji Support
Common emojis: :smile: :heart: :rocket: :star: :thumbsup:
More emojis: :fire: :100: :tada: :eyes: :muscle:

Text with :heart: in the middle should work.

## Combined Features
URL with emoji: Check out https://github.com :rocket:  
Escaped characters: \*not bold\* and \`not code\`

Mixed content: Visit https://example.com for more info! :thumbsup:  
This line has forced break.

## Edge Cases
Incomplete emoji: :invalid_emoji:
URL-like text: not://a.real.url
Escaped emoji: \:smile\:
