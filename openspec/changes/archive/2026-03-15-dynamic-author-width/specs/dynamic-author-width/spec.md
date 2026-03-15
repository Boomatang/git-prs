## ADDED Requirements

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
The formatter SHALL truncate the AUTHOR column before truncating the TITLE column when terminal width is constrained.

#### Scenario: Constrained terminal truncates author first
- **WHEN** terminal width cannot fit all columns at natural sizes
- **THEN** AUTHOR column shrinks first while TITLE retains more space

#### Scenario: Minimum author width preserved
- **WHEN** AUTHOR column is truncated
- **THEN** AUTHOR column SHALL NOT shrink below 6 characters

#### Scenario: Title truncation after author minimum reached
- **WHEN** AUTHOR is already at minimum width (6) and terminal is still constrained
- **THEN** TITLE column shrinks to accommodate (down to its minimum of 20)
