## ADDED Requirements

### Requirement: Team name CLI argument
The `team` subcommand SHALL accept an optional team name as a positional argument.

#### Scenario: Explicit team name provided
- **WHEN** user runs `git_prs team release`
- **THEN** the system uses the team named "release"

#### Scenario: Team name not found
- **WHEN** user runs `git_prs team nonexistent`
- **THEN** the system SHALL return an error indicating the team was not found

### Requirement: Default team selection
When no team name argument is provided, the system SHALL use the default team if configured.

#### Scenario: Default team configured
- **WHEN** `teams.default` is set to "release" and user runs `git_prs team`
- **THEN** the system uses the team named "release"

### Requirement: Single team auto-selection
When only one team is defined and no `default` is set, that team SHALL be used automatically.

#### Scenario: Single team without default
- **WHEN** config has exactly one team named "release" and no `default` key
- **THEN** running `git_prs team` uses the "release" team

### Requirement: Multiple teams require selection
When multiple teams exist without a default, the user MUST specify a team name.

#### Scenario: Multiple teams no default no argument
- **WHEN** config has multiple teams, no `default`, and user runs `git_prs team`
- **THEN** the system SHALL return an error listing available team names
