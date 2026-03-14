## Why

The AUTHOR column in team view is hardcoded to 8 characters, truncating usernames even when the terminal is wide enough to display them fully. This is inconsistent with the ORG/REPO#NUM column which already uses dynamic width based on content.

## What Changes

- Add `calcMaxAuthorWidth()` function following the existing pattern for identifier width calculation
- Make AUTHOR column width dynamic based on the longest author name in the result set
- Implement truncation priority: AUTHOR is truncated first when terminal width is constrained, before TITLE
- Set minimum author width to 6 characters when truncation is required

## Capabilities

### New Capabilities
- `dynamic-author-width`: AUTHOR column in team view dynamically sizes to fit content, with priority-based truncation when space is constrained

### Modified Capabilities

## Impact

- `src/formatter.zig`: Changes to `formatTeamOutput`, `formatTeamRow`, and new `calcMaxAuthorWidth` function
- Team view output only (mine view does not have an AUTHOR column)
- No API or configuration changes
