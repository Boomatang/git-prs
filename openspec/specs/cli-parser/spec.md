## ADDED Requirements

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

### Requirement: Parse subcommand help with context
The CLI parser SHALL return a help command with context indicating which subcommand's help was requested.

#### Scenario: Help for mine command
- **WHEN** user runs `git-prs mine --help`
- **THEN** parser returns Command.help with target=mine

#### Scenario: Help for mine command with -h flag
- **WHEN** user runs `git-prs mine -h`
- **THEN** parser returns Command.help with target=mine

#### Scenario: Help for team command
- **WHEN** user runs `git-prs team --help`
- **THEN** parser returns Command.help with target=team

#### Scenario: Help for merged command
- **WHEN** user runs `git-prs merged --help`
- **THEN** parser returns Command.help with target=merged

#### Scenario: Top-level help
- **WHEN** user runs `git-prs --help`
- **THEN** parser returns Command.help with target=main

### Requirement: Display subcommand-specific help
The CLI SHALL display help specific to the subcommand when help is requested for that subcommand.

#### Scenario: Mine help displays mine-specific content
- **WHEN** user runs `git-prs mine --help`
- **THEN** output includes "git-prs mine" usage and mine-specific options (--org, --limit, --since, --until, --json)

#### Scenario: Team help displays team-specific content
- **WHEN** user runs `git-prs team --help`
- **THEN** output includes "git-prs team" usage and team-specific options (--org, --member, --since, --until, --json)

#### Scenario: Merged help displays merged-specific content
- **WHEN** user runs `git-prs merged --help`
- **THEN** output includes "git-prs merged" usage and merged-specific options (--days, --org, --since, --until, --json)

### Requirement: Parse --version with --json flag
The CLI parser SHALL scan all arguments for `--version` flag before subcommand parsing, and check for `--json` flag when `--version` is found.

#### Scenario: Version flag alone
- **WHEN** args contain `--version` without `--json`
- **THEN** parser returns version command with json=false

#### Scenario: Version flag with --json
- **WHEN** args contain both `--version` and `--json` in any order
- **THEN** parser returns version command with json=true

#### Scenario: Version flag scanned before subcommand parsing
- **WHEN** args are `mine --version`
- **THEN** parser returns version command (not mine command)

#### Scenario: Version flag with json in subcommand context
- **WHEN** args are `team --json --version`
- **THEN** parser returns version command with json=true

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
