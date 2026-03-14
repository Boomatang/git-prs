## Why

Draft PRs indicate work in progress, which is valuable context when reviewing a list of open PRs. Currently there's no way to distinguish draft PRs from ready-for-review PRs. Adding this visibility helps developers quickly identify which PRs are still being worked on versus which need attention, without adding column clutter when there are no drafts.

## What Changes

- Add `is_draft` field to `PullRequest` struct and fetch `isDraft` from GitHub GraphQL API
- Style entire row with dim + italic ANSI codes (`\x1b[2;3m`) for draft PRs
- Only apply ANSI styling when stdout is a TTY (piped output remains plain)
- Include `is_draft` in JSON output for programmatic access

## Capabilities

### New Capabilities

- `draft-pr-styling`: Visual differentiation of draft PRs using ANSI escape codes, with TTY detection to avoid escape codes in piped output

### Modified Capabilities

## Impact

- `src/github.zig`: Add `is_draft` to struct, update GraphQL query, parse response
- `src/formatter.zig`: Add TTY detection, wrap draft rows with ANSI codes, add field to JSON output
- Both `mine` and `team` views affected
