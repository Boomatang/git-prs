## Why

The git-prs application has received significant feature additions since the documentation was last updated. Several commands, options, and display behaviors are undocumented, making it difficult for users to discover and use the full capabilities of the tool.

## What Changes

- Document the new `merged` command with all its options (`--days`, `--since`, `--until`, `--org`, `--json`)
- Document `--since` and `--until` date filtering options for `mine` and `team` commands
- Document named teams feature (positional team name argument for `team` command)
- Update configuration guide with named teams configuration structure
- Document draft PR visual styling (dim+italic display)
- Document dynamic terminal width detection and adaptive display features
- Update README features list to reflect current capabilities

## Capabilities

### New Capabilities

- `merged-command-docs`: Documentation for the new `merged` command that lists recently merged PRs
- `date-filtering-docs`: Documentation for `--since` and `--until` date filtering across commands
- `named-teams-docs`: Documentation for named teams configuration and CLI usage

### Modified Capabilities

- `documentation`: Existing docs need updates for new features, display behaviors, and configuration options

## Impact

- `docs/cli-reference.md` - Add merged command section, date filtering options, named teams usage
- `docs/config-guide.md` - Add named teams configuration structure and examples
- `README.md` - Update features list with new capabilities
