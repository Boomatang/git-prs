## ADDED Requirements

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
