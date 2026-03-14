## Why

Teams often work across multiple GitHub orgs, and not all team members are part of every org. The current config structure is org-centric (keyed by org name), making it impossible to define a logical team that spans orgs. Users need named teams like "release" or "traffic" that can search across multiple orgs for specific members.

## What Changes

- **BREAKING**: Replace `"team"` config key with new `"teams"` structure
- Add named teams with explicit `orgs` and `members` per team
- Add `"default"` field to specify which team to use for bare `git_prs team` command
- Add CLI argument: `git_prs team [name]` to select a specific team
- Single team auto-selected when only one defined; multiple teams require `default` or explicit name
- Validation: empty `orgs` or `members` arrays are errors

## Capabilities

### New Capabilities
- `named-teams-config`: Configuration structure for named teams with explicit orgs and members per team
- `team-selection`: CLI team selection via argument with default fallback logic

### Modified Capabilities

## Impact

- `src/config.zig`: New `teams` parsing replacing `team`, new validation rules
- `src/cli.zig`: New optional team name argument for team subcommand
- `src/main.zig`: Team selection logic (default, single-team auto-select, explicit name)
- Config file format: Breaking change from `"team"` to `"teams"` structure
