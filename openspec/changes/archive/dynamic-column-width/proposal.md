## Why

The ORG/REPO#NUM column is currently hardcoded to 25 characters, truncating long organization and repository names. This makes it difficult to identify which PRs are being displayed when org/repo names are longer than the column width.

## What Changes

- The ORG/REPO#NUM column width will be dynamically calculated based on the longest identifier in the result set
- Column width expands to fit content rather than truncating
- Rows are allowed to exceed terminal width if necessary to show full identifiers
- Title column width remains flexible but no longer compensates for a fixed identifier column

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `output-formatter`: Change ORG/REPO#NUM column from fixed 25-character width with truncation to dynamic width based on content

## Impact

- `src/formatter.zig`: Primary changes to column width calculation and row formatting
- Output format: Rows may exceed terminal width when org/repo names are long
- No API changes, no breaking changes to CLI interface
