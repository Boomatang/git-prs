## Why

Users need control over how PRs are displayed to support different workflows: prioritization (seeing oldest PRs first) and context-switching (grouping PRs by repository). Currently, sort order is hardcoded per command with no way to customize it.

## What Changes

- Add `--sort <field>[:direction]` flag to `mine`, `team`, and `merged` commands
- Support multiple `--sort` flags applied left-to-right (primary, secondary, etc.)
- Sortable fields: `age`, `author`, `repo`, `comments`, `last`
- Direction defaults to `asc` if not specified; valid values are `asc` and `desc`
- Null values in `last` field sort as "smallest" (first in asc, last in desc)
- Validate that `--sort author` is not allowed for `mine` command (error)
- Preserve existing default sort orders when no `--sort` flags provided:
  - `mine`: `age:desc` (newest first)
  - `team`: `author:asc`, then `age:desc`
  - `merged`: `age:desc` (newest first)

## Capabilities

### New Capabilities

- `sort-flags`: CLI parsing and application of configurable sort order for PR output

### Modified Capabilities

- `cli-parser`: Add --sort flag parsing with field:direction syntax and validation
- `output-formatter`: Apply user-specified sort criteria instead of hardcoded sort functions

## Impact

- `src/cli.zig`: Add SortCriteria struct, parse multiple --sort flags, validate field applicability per command
- `src/formatter.zig`: Replace `sortByAge` and `sortByAuthorThenAge` with generic multi-criteria sort function
- Help text for all commands needs updating to document --sort flag
