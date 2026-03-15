## Why

Teams form and disband, and members move between teams. When querying team PRs, users need to see only PRs created during the team's existence - not ancient PRs from before the team formed or PRs created after a team disbanded.

## What Changes

- **BREAKING**: Team configuration format changes from array of members to object with `members`, `since`, and `until` fields
- Add optional `since` and `until` date fields to team configuration for date range filtering
- Add `--since` and `--until` CLI flags to the `team` command (override config defaults)
- Add `--since` and `--until` CLI flags to the `mine` command (CLI only, no config)
- Filter PRs server-side using GitHub search query date syntax (`created:>=YYYY-MM-DD created:<=YYYY-MM-DD`)

## Capabilities

### New Capabilities
- `date-filtering`: Date range filtering for PR queries using `since` and `until` parameters, applied server-side via GitHub search query syntax

### Modified Capabilities
- None

## Impact

- `src/config.zig`: Team parsing changes from array to object format
- `src/cli.zig`: New `--since` and `--until` flags for both `mine` and `team` commands
- `src/github.zig`: GraphQL search query modified to include date range filters
- Config file format: Breaking change requiring users to update their `config.json`
