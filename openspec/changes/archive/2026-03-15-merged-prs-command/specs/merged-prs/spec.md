## ADDED Requirements

### Requirement: Merged command exists

The CLI SHALL support a `merged` subcommand that lists merged PRs authored by the authenticated user.

#### Scenario: Run merged command
- **WHEN** the user runs `git-prs merged`
- **THEN** the system SHALL display merged PRs from the last 7 days

### Requirement: Default 7-day window

The `merged` command SHALL default to showing PRs merged in the last 7 days when no date flags are provided.

#### Scenario: Default window
- **WHEN** the user runs `git-prs merged` without date flags
- **THEN** the system SHALL show PRs merged from 7 days ago until today

### Requirement: Days flag adjusts window

The `--days N` flag SHALL adjust the window to the last N days from today.

#### Scenario: Custom days window
- **WHEN** the user runs `git-prs merged --days 14`
- **THEN** the system SHALL show PRs merged from 14 days ago until today

### Requirement: Since and until flags for explicit range

The `--since` and `--until` flags SHALL allow specifying an explicit date range for merged PRs.

#### Scenario: Explicit date range
- **WHEN** the user runs `git-prs merged --since 2026-03-01 --until 2026-03-14`
- **THEN** the system SHALL show PRs merged between those dates (inclusive)

#### Scenario: Since without until
- **WHEN** the user runs `git-prs merged --since 2026-03-01`
- **THEN** the system SHALL show PRs merged from that date until today

### Requirement: Days flag mutually exclusive with since/until

The `--days` flag SHALL NOT be allowed in combination with `--since` or `--until`.

#### Scenario: Days with since rejected
- **WHEN** the user runs `git-prs merged --days 7 --since 2026-03-01`
- **THEN** the system SHALL display an error message and exit

#### Scenario: Days with until rejected
- **WHEN** the user runs `git-prs merged --days 7 --until 2026-03-14`
- **THEN** the system SHALL display an error message and exit

### Requirement: Plain URL output format

The default output format SHALL be plain URLs, one per line, with no additional formatting.

#### Scenario: Plain output
- **WHEN** the user runs `git-prs merged`
- **THEN** the output SHALL contain one URL per line

#### Scenario: Plain output format
- **WHEN** merged PRs are found
- **THEN** each line SHALL contain only the PR URL (e.g., `https://github.com/org/repo/pull/123`)

### Requirement: Human-friendly empty result message

When no merged PRs are found, the system SHALL display a human-friendly message.

#### Scenario: No results message
- **WHEN** no PRs were merged in the specified window
- **THEN** the system SHALL display "No PRs merged in the last N days" (or appropriate message for explicit range)

### Requirement: JSON output flag

The `--json` flag SHALL output merged PRs as a JSON array of PR objects.

#### Scenario: JSON output
- **WHEN** the user runs `git-prs merged --json`
- **THEN** the output SHALL be a JSON array containing PR objects

#### Scenario: JSON empty result
- **WHEN** no PRs were merged and `--json` flag is used
- **THEN** the output SHALL be an empty JSON array `[]`

### Requirement: Org filter flag

The `--org` flag SHALL filter merged PRs to a specific organization.

#### Scenario: Filter by org
- **WHEN** the user runs `git-prs merged --org kubernetes`
- **THEN** only merged PRs from the kubernetes organization SHALL be displayed

### Requirement: Query uses merged date filter

The GitHub API query SHALL filter by merge date, not creation date.

#### Scenario: Merged date filtering
- **WHEN** fetching merged PRs with a date range
- **THEN** the query SHALL use `merged:>=DATE` syntax (not `created:>=DATE`)
