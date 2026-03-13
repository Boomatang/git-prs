## ADDED Requirements

### Requirement: Parse mine command
The CLI parser SHALL recognize the `mine` subcommand for viewing the user's own PRs.

#### Scenario: Mine command with no flags
- **WHEN** user runs `git-prs mine`
- **THEN** parser returns MineArgs with org_filter=null and limit=50

#### Scenario: Mine command with org filter
- **WHEN** user runs `git-prs mine --org kubernetes`
- **THEN** parser returns MineArgs with org_filter="kubernetes" and limit=50

#### Scenario: Mine command with limit
- **WHEN** user runs `git-prs mine --limit 10`
- **THEN** parser returns MineArgs with org_filter=null and limit=10

#### Scenario: Mine command with both flags
- **WHEN** user runs `git-prs mine --org kubernetes --limit 25`
- **THEN** parser returns MineArgs with org_filter="kubernetes" and limit=25

### Requirement: Parse team command
The CLI parser SHALL recognize the `team` subcommand for viewing team members' PRs.

#### Scenario: Team command with org
- **WHEN** user runs `git-prs team --org my-company`
- **THEN** parser returns TeamArgs with org="my-company" and member_filter=null

#### Scenario: Team command with org and member filter
- **WHEN** user runs `git-prs team --org my-company --member alice`
- **THEN** parser returns TeamArgs with org="my-company" and member_filter="alice"

#### Scenario: Team command without org (single team configured)
- **WHEN** user runs `git-prs team` and only one team is configured
- **THEN** parser returns TeamArgs with the single configured org and member_filter=null

### Requirement: Handle invalid commands
The CLI parser SHALL provide clear error messages for invalid input.

#### Scenario: Unknown subcommand
- **WHEN** user runs `git-prs unknown`
- **THEN** parser exits with error "Unknown command: unknown. Use 'mine' or 'team'."

#### Scenario: Missing required org for team with multiple teams
- **WHEN** user runs `git-prs team` and multiple teams are configured
- **THEN** parser exits with error "Multiple teams configured. Specify --org: org1, org2"

#### Scenario: Invalid flag
- **WHEN** user runs `git-prs mine --invalid`
- **THEN** parser exits with error describing the invalid flag

### Requirement: Help output
The CLI parser SHALL display usage information when requested.

#### Scenario: Help flag
- **WHEN** user runs `git-prs --help`
- **THEN** parser displays usage information and exits successfully

#### Scenario: No arguments
- **WHEN** user runs `git-prs` with no arguments
- **THEN** parser displays usage information and exits successfully
