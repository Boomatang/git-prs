## ADDED Requirements

### Requirement: Team configuration with date range
The system SHALL accept team definitions as objects with `members` (required), `since` (optional), and `until` (optional) fields. The `since` and `until` fields SHALL use YYYY-MM-DD date format.

#### Scenario: Team with all fields specified
- **WHEN** config contains a team with `members`, `since`, and `until` fields
- **THEN** the system SHALL parse all fields and use them for PR filtering

#### Scenario: Team with only since date
- **WHEN** config contains a team with `members` and `since` but no `until`
- **THEN** the system SHALL filter PRs created on or after the `since` date with no upper bound

#### Scenario: Team with only until date
- **WHEN** config contains a team with `members` and `until` but no `since`
- **THEN** the system SHALL filter PRs created on or before the `until` date with no lower bound

#### Scenario: Team with no dates
- **WHEN** config contains a team with only `members` and no date fields
- **THEN** the system SHALL return all PRs without date filtering

#### Scenario: Invalid date format in config
- **WHEN** config contains a team with an invalid date format (not YYYY-MM-DD)
- **THEN** the system SHALL reject the config with an error message indicating the invalid date

### Requirement: CLI date flags for team command
The `team` command SHALL accept `--since` and `--until` flags with YYYY-MM-DD format dates that override any dates specified in the team configuration.

#### Scenario: CLI since flag overrides config
- **WHEN** user runs `git-prs team --org X --since 2025-03-01` and config has `since: "2025-01-01"`
- **THEN** the system SHALL use `2025-03-01` as the since date

#### Scenario: CLI until flag overrides config
- **WHEN** user runs `git-prs team --org X --until 2025-06-30` and config has `until: "2025-12-31"`
- **THEN** the system SHALL use `2025-06-30` as the until date

#### Scenario: CLI flags with no config dates
- **WHEN** user runs `git-prs team --org X --since 2025-01-01 --until 2025-12-31` and config has no dates
- **THEN** the system SHALL use the CLI-provided dates for filtering

#### Scenario: Invalid date format in CLI
- **WHEN** user provides an invalid date format via `--since` or `--until`
- **THEN** the system SHALL display an error message and exit

### Requirement: CLI date flags for mine command
The `mine` command SHALL accept `--since` and `--until` flags with YYYY-MM-DD format dates for filtering PRs by creation date.

#### Scenario: Mine with since flag
- **WHEN** user runs `git-prs mine --since 2025-01-01`
- **THEN** the system SHALL return only PRs created on or after `2025-01-01`

#### Scenario: Mine with until flag
- **WHEN** user runs `git-prs mine --until 2025-06-30`
- **THEN** the system SHALL return only PRs created on or before `2025-06-30`

#### Scenario: Mine with both flags
- **WHEN** user runs `git-prs mine --since 2025-01-01 --until 2025-06-30`
- **THEN** the system SHALL return only PRs created between `2025-01-01` and `2025-06-30` inclusive

### Requirement: Server-side date filtering
The system SHALL filter PRs by creation date using GitHub search query syntax (`created:>=YYYY-MM-DD` and `created:<=YYYY-MM-DD`) rather than client-side filtering.

#### Scenario: Since date applied to search query
- **WHEN** a since date is specified (via config or CLI)
- **THEN** the GitHub search query SHALL include `created:>=YYYY-MM-DD`

#### Scenario: Until date applied to search query
- **WHEN** an until date is specified (via config or CLI)
- **THEN** the GitHub search query SHALL include `created:<=YYYY-MM-DD`

#### Scenario: Both dates applied to search query
- **WHEN** both since and until dates are specified
- **THEN** the GitHub search query SHALL include both `created:>=YYYY-MM-DD` and `created:<=YYYY-MM-DD`

### Requirement: Inclusive date boundaries
Both `since` and `until` dates SHALL be inclusive, meaning PRs created exactly on those dates are included in results.

#### Scenario: PR created on since date
- **WHEN** a PR was created on `2025-01-15` and `since` is `2025-01-15`
- **THEN** the PR SHALL be included in results

#### Scenario: PR created on until date
- **WHEN** a PR was created on `2025-06-30` and `until` is `2025-06-30`
- **THEN** the PR SHALL be included in results
