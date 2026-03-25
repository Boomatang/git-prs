## ADDED Requirements

(none)

## MODIFIED Requirements

### Requirement: Dynamic author column width

The formatter SHALL dynamically size the AUTHOR column based on the longest author name in the result set.

#### Scenario: Column width based on content
- **WHEN** formatter receives PRs with authors of varying username lengths
- **THEN** formatter calculates column width from the longest author name

#### Scenario: Full author display when space available
- **WHEN** terminal width accommodates all columns at their natural sizes
- **THEN** formatter displays complete author usernames without truncation

#### Scenario: Short usernames do not waste space
- **WHEN** all authors have usernames of 5 characters or fewer
- **THEN** author column width SHALL be 6 characters (minimum header width)

### Requirement: Author truncation priority

The formatter SHALL truncate the AUTHOR column after truncating the TITLE column when terminal width is constrained.

#### Scenario: Constrained terminal truncates title first
- **WHEN** terminal width cannot fit all columns at natural sizes
- **THEN** TITLE column shrinks first while AUTHOR retains full width

#### Scenario: Author truncates after title reaches minimum
- **WHEN** TITLE column is already at minimum width (3 characters) and terminal is still constrained
- **THEN** AUTHOR column shrinks to accommodate

#### Scenario: Minimum author width preserved
- **WHEN** AUTHOR column is truncated
- **THEN** AUTHOR column SHALL NOT shrink below 4 characters plus "..." (7 total)

#### Scenario: Identifier truncation after author minimum reached
- **WHEN** AUTHOR is already at minimum width (7) and terminal is still constrained
- **THEN** identifier components (ORG, then REPO) shrink to accommodate

## REMOVED Requirements

(none)
