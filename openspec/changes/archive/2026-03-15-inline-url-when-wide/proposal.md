## Why

Currently, PR URLs are always displayed on a separate line below the PR data, wasting vertical space. When the terminal is wide enough to fit all information on one line, the URL should be displayed inline to provide a more compact, scannable output.

## What Changes

- PR URLs will be displayed on the same line as other PR data when terminal width allows
- When terminal is too narrow, the current behavior (URL on separate indented line) will be preserved
- Both `mine` and `team` output formats will be updated

## Capabilities

### New Capabilities

- `inline-url-display`: Adaptive URL display that shows the PR URL inline when terminal width permits, falling back to the current two-line format for narrow terminals

### Modified Capabilities

<!-- None - this is adding new adaptive behavior, not changing existing spec requirements -->

## Impact

- `src/formatter.zig`: `formatMineRow` and `formatTeamRow` functions will need to calculate whether the URL fits and conditionally format output
- Output format changes may affect users who parse the text output (JSON output remains unchanged)
