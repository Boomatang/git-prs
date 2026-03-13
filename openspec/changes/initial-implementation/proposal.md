## Why

Checking the status of open PRs across multiple GitHub organizations is time-consuming. Developers and team leads spend Monday mornings manually navigating GitHub to see which PRs need attention, which are stale, and which team members might need support. A CLI tool that aggregates this information would save significant time and surface problems earlier.

## What Changes

- New CLI tool `git-prs` with two commands:
  - `git-prs mine` - shows your open PRs across configured orgs
  - `git-prs team` - shows team members' open PRs in an org
- JSON config file for specifying orgs and team members
- Integration with `gh` CLI for authentication (no token management)
- Compact table output showing PR health signals (age, commenters, last activity)

## Capabilities

### New Capabilities

- `cli-parser`: Command-line argument parsing for `mine` and `team` commands with flags
- `config-loader`: XDG config file loading, validation, and `gh auth token` integration
- `github-client`: GitHub GraphQL API client for fetching PR data with pagination
- `output-formatter`: Table rendering with column truncation and time formatting

### Modified Capabilities

(none - this is the initial implementation)

## Impact

- **New files**: `src/main.zig` will be replaced with actual CLI implementation
- **New files**: Additional source files for each component (config, github, formatter)
- **Dependencies**: None external; uses only Zig standard library
- **Runtime dependency**: Requires `gh` CLI to be installed and authenticated
- **Config file**: Users will need to create `~/.config/git-prs/config.json`
