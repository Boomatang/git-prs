## Why

The title column is sized to fill all remaining terminal width after fixed columns, even when actual PR titles are much shorter. This wastes horizontal space and makes the output harder to read, especially when the longest title is significantly shorter than the available width.

## What Changes

- Calculate maximum title length from actual PR data
- Size the title column based on the smaller of: (1) available terminal width, or (2) actual maximum title length plus a small margin
- Maintain minimum title width of 20 characters for readability

## Capabilities

### New Capabilities

- `adaptive-title-width`: Title column adapts to actual content width rather than consuming all available space

### Modified Capabilities

None

## Impact

- `src/formatter.zig`: Changes to `formatMineOutput` and `formatTeamOutput` functions
- Title column will be narrower when PR titles are short
- No breaking changes to output format or API
