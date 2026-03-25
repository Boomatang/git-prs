## Why

On narrow terminals, the current behavior moves the URL to a second line below the PR data. This doubles the vertical space per PR and breaks visual scanning. Users want a consistent single-line format where the URL always stays in the header row, with other columns truncating as needed to make room.

## What Changes

- Remove two-line URL display mode entirely - URL always appears inline on the same row
- Change truncation priority: Title truncates first, then Author, then Identifier (ORG before REPO)
- Lower minimum column widths to allow more aggressive truncation when space is constrained
- URL never truncates and may cause natural terminal line wrapping on very narrow displays
- Header always includes URL column regardless of terminal width

## Capabilities

### New Capabilities

- `identifier-truncation`: Cascading truncation within the ORG/REPO#NUM identifier, truncating ORG first (min 4 chars), then REPO (min 4 chars), with number never truncated

### Modified Capabilities

- `inline-url-display`: Remove two-line display mode and per-row format decision; URL is always inline
- `dynamic-author-width`: Reverse truncation priority - title truncates before author, author before identifier; lower minimum author width to 4 characters

## Impact

- `src/formatter.zig`: Remove `urlFitsInline()` function and two-line display code paths; add identifier truncation logic; update truncation priority chain
- Test updates: Remove tests for two-line URL display; add tests for cascading truncation
- Visual change: Users on narrow terminals will see truncated columns instead of URL on second line
