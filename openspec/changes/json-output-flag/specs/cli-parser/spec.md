## ADDED Requirements

### Requirement: Parse --json flag for mine command
The CLI parser SHALL accept `--json` flag for the mine command.

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
The CLI parser SHALL accept `--json` flag for the team command.

#### Scenario: Team with --json flag
- **WHEN** user runs `git-prs team --org mycompany --json`
- **THEN** parser returns TeamArgs with json=true and org="mycompany"

#### Scenario: Team without --json flag
- **WHEN** user runs `git-prs team --org mycompany`
- **THEN** parser returns TeamArgs with json=false (default)
