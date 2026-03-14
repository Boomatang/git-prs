## Why

The PR list currently displays oldest PRs at the top. Users expect newest PRs first (at top) with oldest at the bottom, matching the typical workflow of reviewing recent activity first.

## What Changes

- Reverse PR sort order: newest PRs appear first, oldest last
- Applies to both `mine` and `team` commands
- Within team view author groups, newest PRs from each author appear first

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `output-formatter`: Change sort order from oldest-first to newest-first

## Impact

- `src/formatter.zig`: Reverse comparison in `sortByAge` and `sortByAuthorThenAge` functions
- Tests: Update expected sort order in sorting tests
- Design spec: Update sort order documentation
