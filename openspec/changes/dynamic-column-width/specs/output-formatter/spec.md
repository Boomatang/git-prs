## ADDED Requirements

### Requirement: Dynamic identifier column width
The output formatter SHALL dynamically size the ORG/REPO#NUM column to fit the longest identifier in the result set.

#### Scenario: Column width based on content
- **WHEN** formatter receives PRs with identifiers of varying lengths
- **THEN** formatter calculates column width from the longest identifier

#### Scenario: Full identifier display
- **WHEN** formatter renders a PR row
- **THEN** formatter displays the complete org/repo#number without truncation

#### Scenario: Row width exceeds terminal
- **WHEN** identifier column plus other columns exceeds terminal width
- **THEN** formatter outputs the full row (allowing terminal to handle overflow)

## MODIFIED Requirements

### Requirement: Truncate long content
The output formatter SHALL truncate content to fit column widths.

#### Scenario: Truncate long title
- **WHEN** PR title exceeds available width
- **THEN** formatter truncates title and appends "..."

#### Scenario: Truncate long author name
- **WHEN** author username exceeds 8 characters
- **THEN** formatter truncates to 5 characters and appends "..."

## REMOVED Requirements

### Requirement: Truncate long org/repo
**Reason**: Replaced by dynamic identifier column width to show full identifiers
**Migration**: No migration needed; output will now show full identifiers instead of truncated ones
