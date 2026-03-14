## ADDED Requirements

### Requirement: Display personal PR table
The output formatter SHALL display PRs in a compact table format for the `mine` command.

#### Scenario: Display PR list
- **WHEN** formatter receives list of PRs for mine command
- **THEN** formatter outputs table with columns: ORG/REPO#NUM, TITLE, AGE, 👤, LAST

#### Scenario: No PRs found
- **WHEN** formatter receives empty PR list
- **THEN** formatter outputs "No open PRs found" and exits with code 0

### Requirement: Display team PR table
The output formatter SHALL display PRs with author information for the `team` command.

#### Scenario: Display team PR list
- **WHEN** formatter receives list of PRs for team command
- **THEN** formatter outputs table with columns: AUTHOR, ORG/REPO#NUM, TITLE, AGE, 👤, LAST

#### Scenario: Sort by author then age
- **WHEN** PRs are from multiple team members
- **THEN** formatter groups PRs by author with oldest PRs first within each group

### Requirement: Format time durations
The output formatter SHALL display durations in human-readable format.

#### Scenario: Duration under one hour
- **WHEN** duration is 45 minutes
- **THEN** formatter displays "45m"

#### Scenario: Duration in hours
- **WHEN** duration is 3 hours
- **THEN** formatter displays "3h"

#### Scenario: Duration in days
- **WHEN** duration is 3 days
- **THEN** formatter displays "3d"

#### Scenario: Duration in weeks
- **WHEN** duration is 14 days
- **THEN** formatter displays "2w"

#### Scenario: Duration in months
- **WHEN** duration is 56 days
- **THEN** formatter displays "2mo" (using 28-day months)

#### Scenario: No last comment
- **WHEN** PR has no comments
- **THEN** formatter displays "-" in LAST column

### Requirement: Truncate long content
The output formatter SHALL truncate content to fit column widths.

#### Scenario: Truncate long title
- **WHEN** PR title exceeds available width
- **THEN** formatter truncates title and appends "..."

#### Scenario: Truncate long author name
- **WHEN** author username exceeds 8 characters
- **THEN** formatter truncates to 5 characters and appends "..."

#### Scenario: Truncate long org/repo
- **WHEN** org/repo#num exceeds 25 characters
- **THEN** formatter truncates org/repo portion keeping #NUM visible

### Requirement: Detect terminal width
The output formatter SHALL adapt to terminal width.

#### Scenario: COLUMNS environment variable set
- **WHEN** COLUMNS env var is set to 120
- **THEN** formatter uses 120 as terminal width

#### Scenario: COLUMNS not set
- **WHEN** COLUMNS env var is not set
- **THEN** formatter defaults to 80 columns

### Requirement: Sort PRs by age
The output formatter SHALL sort PRs with oldest first.

#### Scenario: Sort order
- **WHEN** formatter receives PRs with ages 1d, 5d, 2d
- **THEN** formatter outputs in order: 5d, 2d, 1d (oldest first)

### Requirement: Output PR URLs
The output formatter SHALL include clickable PR URLs.

#### Scenario: URL format
- **WHEN** formatter outputs PR row
- **THEN** ORG/REPO#NUM links to full GitHub URL (https://github.com/org/repo/pull/123)
