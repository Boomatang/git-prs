## Why

When URLs are displayed inline (on wide terminals), the table header is incomplete: it lacks a "URL" column header and the separator line doesn't extend to cover the URL column. This makes the table look inconsistent and unprofessional.

## What Changes

- Add "URL" header column when inline URL display mode is active
- Extend header separator line to include URL column width when inline mode is active

## Capabilities

### New Capabilities

- `inline-url-header`: Header row includes URL column and separator extends full table width when inline URL mode is active

### Modified Capabilities

None

## Impact

- `src/formatter.zig`: Changes to header rendering in `formatMineOutput` and `formatTeamOutput` functions
- Header output changes only when inline URL mode is active (wide terminals)
- No breaking changes
