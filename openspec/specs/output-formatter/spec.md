## ADDED Requirements

### Requirement: Display PR URL below each row
The output formatter SHALL display the full GitHub PR URL on a line below each PR data row.

#### Scenario: URL displayed in mine view
- **WHEN** formatter renders a PR row in mine output
- **THEN** formatter outputs the URL on the following line, indented with 4 spaces

#### Scenario: URL displayed in team view
- **WHEN** formatter renders a PR row in team output
- **THEN** formatter outputs the URL on the following line, indented with 4 spaces

#### Scenario: Full URL without truncation
- **WHEN** formatter outputs the URL line
- **THEN** the complete URL is displayed without any truncation

## MODIFIED Requirements

(none)

## REMOVED Requirements

(none)
