## Why

The current table output is human-readable but not machine-readable. Adding a `--json` flag enables piping output to other tools like `jq`, integrating with scripts, and building workflows that process PR data programmatically.

## What Changes

- Add `--json` flag to both `mine` and `team` commands
- When `--json` is specified, output PR data as a JSON array instead of formatted table
- JSON output includes all PR fields (org, repo, number, title, url, author, created_at, last_comment_at, unique_commenters)
- JSON output writes to stdout without headers or formatting

## Capabilities

### New Capabilities

- `json-output`: JSON serialization of PR data for machine-readable output

### Modified Capabilities

- `cli-parser`: Add `--json` flag parsing to MineArgs and TeamArgs

## Impact

- `src/cli.zig`: Add `json: bool` field to MineArgs and TeamArgs, parse `--json` flag
- `src/formatter.zig`: Add `formatJsonOutput` function for JSON serialization
- `src/main.zig`: Check for json flag and call appropriate formatter
- No breaking changes - existing table output remains the default
