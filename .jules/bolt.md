## 2026-06-07 - [Markdown Fast-Path Optimization]
**Learning:** Checking for formatting strings prior to evaluating complex regex patterns can be significantly faster on typical prose, but must properly capture ALL required Markdown characters (including `:` for emoji, and `http://` for bare URLs) to avoid breaking rendering.
**Action:** Always enumerate every possible inline token starting character before deciding a line is plain text, rather than relying on a small subset.
