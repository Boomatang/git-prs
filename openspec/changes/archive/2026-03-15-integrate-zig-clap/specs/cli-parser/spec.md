## MODIFIED Requirements

### Requirement: Parse --json flag for mine command
The CLI parser SHALL accept `--json` flag for the mine command using zig-clap parameter definition.

#### Scenario: Mine with --json flag
- **WHEN** user runs `git-prs mine --json`
- **THEN** parser returns MineArgs with json=true

#### Scenario: Mine without --json flag
- **WHEN** user runs `git-prs mine`
- **THEN** parser returns MineArgs with json=false (default)

#### Scenario: Mine with --json and other flags
- **WHEN** user runs `git-prs mine --org kubernetes --json --limit 10`
- **THEN** parser returns MineArgs with json=true, org_filter="kubernetes", limit=10

### Requirement: Parse --json flag for team command
The CLI parser SHALL accept `--json` flag for the team command using zig-clap parameter definition.

#### Scenario: Team with --json flag
- **WHEN** user runs `git-prs team --org mycompany --json`
- **THEN** parser returns TeamArgs with json=true and org="mycompany"

#### Scenario: Team without --json flag
- **WHEN** user runs `git-prs team --org mycompany`
- **THEN** parser returns TeamArgs with json=false (default)

## ADDED Requirements

### Requirement: Parse arguments using zig-clap
The CLI parser SHALL use zig-clap library for all argument parsing instead of manual parsing functions.

#### Scenario: Successful argument parsing via clap
- **WHEN** user runs `git-prs mine --org kubernetes --limit 10`
- **THEN** zig-clap parses arguments and returns MineArgs with org_filter="kubernetes" and limit=10

#### Scenario: Unknown flag handling via clap
- **WHEN** user runs `git-prs mine --unknown-flag`
- **THEN** zig-clap returns an error for unrecognized option

### Requirement: Mutual exclusivity validation for merged command
The CLI parser SHALL validate that `--days` is mutually exclusive with `--since` and `--until` for the merged command.

#### Scenario: Days with since rejected
- **WHEN** user runs `git-prs merged --days 7 --since 2025-01-01`
- **THEN** parser returns DaysWithDateRange error

#### Scenario: Days with until rejected
- **WHEN** user runs `git-prs merged --days 7 --until 2025-01-01`
- **THEN** parser returns DaysWithDateRange error

#### Scenario: Since and until without days accepted
- **WHEN** user runs `git-prs merged --since 2025-01-01 --until 2025-06-30`
- **THEN** parser returns MergedArgs with since and until populated

## REMOVED Requirements

### Requirement: Manual argument parsing functions
**Reason**: Replaced by zig-clap declarative parameter definitions
**Migration**: Use zig-clap's `parseParamsComptime()` and `parse()` functions instead of `parseMineArgs()`, `parseTeamArgs()`, `parseMergedArgs()`

### Requirement: Manual help text in printUsage()
**Reason**: Replaced by zig-clap's automatic help generation
**Migration**: Help text is now generated from parameter definitions; remove `printUsage()` function
