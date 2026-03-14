## Why

Developers need to report merged PRs for status updates, often on a weekly cadence. Currently there's no way to list merged PRs with their URLs for easy copy-paste into documents. This feature enables quick extraction of merged PR URLs for reporting purposes.

## What Changes

- Add new `merged` subcommand to list merged PRs authored by the current user
- Default to last 7 days with `--days N` flag to adjust the window
- Support explicit date ranges via `--since` and `--until` flags (mutually exclusive with `--days`)
- Output plain URLs (one per line) by default for easy copy-paste
- Support `--json` flag for consistency with other commands
- Support `--org` flag to filter to specific organization
- Display human-friendly message when no results found (empty array for JSON)

## Capabilities

### New Capabilities

- `merged-prs`: New command to list merged PRs with date range filtering and URL-focused output

### Modified Capabilities

## Impact

- `src/cli.zig`: Add `MergedArgs` struct and `merged` command parsing
- `src/github.zig`: Add function to fetch merged PRs using `is:merged` and `merged:>=DATE` query
- `src/formatter.zig`: Add URL-only output formatter for merged command
- `src/main.zig`: Add handler for merged command
