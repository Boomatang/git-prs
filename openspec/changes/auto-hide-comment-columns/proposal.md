## Why

When displaying PR tables, the comment-related columns (👤 unique commenters and LAST comment time) add visual noise when no PRs have any comments. Hiding these columns automatically creates a cleaner, more focused output when comment data isn't relevant.

## What Changes

- Auto-detect when all PRs in a result set have zero commenters
- Hide the 👤 (unique commenters) column when no comments exist
- Hide the LAST (last comment time) column when no comments exist
- Adjust header and separator width accordingly
- No changes to JSON output (always includes all fields)

## Capabilities

### New Capabilities

- `comment-column-visibility`: Logic to detect comment presence and conditionally display comment-related columns in table output

### Modified Capabilities

- `output-formatter`: Table output now conditionally hides 👤 and LAST columns based on comment presence

## Impact

- `src/formatter.zig`: Add detection function, modify row/header formatting functions
- Mine and Team table views affected
- JSON output unchanged
- No API or configuration changes
