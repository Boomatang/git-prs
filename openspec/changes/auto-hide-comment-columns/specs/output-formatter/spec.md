## ADDED Requirements

### Requirement: Hide comment columns when no comments exist
The output formatter SHALL hide the 👤 (unique commenters) and LAST (last comment time) columns when all PRs have zero commenters.

#### Scenario: Mine view with no comments
- **WHEN** formatter renders mine output AND no PRs have comments
- **THEN** the table displays only: ORG/REPO#NUM, TITLE, AGE columns
- **AND** the 👤 and LAST columns are not displayed

#### Scenario: Team view with no comments
- **WHEN** formatter renders team output AND no PRs have comments
- **THEN** the table displays only: AUTHOR, ORG/REPO#NUM, TITLE, AGE columns
- **AND** the 👤 and LAST columns are not displayed

#### Scenario: Mine view with comments present
- **WHEN** formatter renders mine output AND at least one PR has comments
- **THEN** the table displays all columns: ORG/REPO#NUM, TITLE, AGE, 👤, LAST

#### Scenario: Team view with comments present
- **WHEN** formatter renders team output AND at least one PR has comments
- **THEN** the table displays all columns: AUTHOR, ORG/REPO#NUM, TITLE, AGE, 👤, LAST

### Requirement: Header reflects visible columns
The output formatter SHALL only display column headers for visible columns.

#### Scenario: Header without comment columns
- **WHEN** comment columns are hidden
- **THEN** the header line does not include 👤 or LAST labels

#### Scenario: Separator width matches visible columns
- **WHEN** comment columns are hidden
- **THEN** the separator line width is reduced to match visible columns only

### Requirement: JSON output unchanged
The JSON output formatter SHALL always include `unique_commenters` and `last_comment_at` fields regardless of their values.

#### Scenario: JSON includes all fields when no comments
- **WHEN** formatter renders JSON output AND no PRs have comments
- **THEN** output includes `unique_commenters` and `last_comment_at` fields for each PR

## MODIFIED Requirements

(none)

## REMOVED Requirements

(none)
