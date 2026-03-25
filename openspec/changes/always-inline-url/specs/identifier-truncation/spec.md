## ADDED Requirements

### Requirement: Identifier truncation when space constrained

The formatter SHALL truncate the ORG/REPO#NUM identifier when terminal width cannot accommodate all columns at their minimum widths plus the full URL.

#### Scenario: ORG truncates before REPO
- **WHEN** the identifier must be truncated to fit available space
- **THEN** the ORG component SHALL truncate first
- **AND** the REPO component SHALL remain at full length if possible

#### Scenario: Both ORG and REPO truncate when severely constrained
- **WHEN** truncating ORG alone does not free enough space
- **THEN** REPO SHALL also truncate
- **AND** both components SHALL truncate to their minimum widths before further column truncation

### Requirement: Minimum ORG width

The formatter SHALL preserve at least 4 characters of the ORG name before adding truncation indicator.

#### Scenario: ORG truncation format
- **WHEN** ORG is truncated
- **THEN** the displayed ORG SHALL be at least 4 characters followed by "..."
- **AND** the total ORG display width SHALL be at least 7 characters (4 + "...")

### Requirement: Minimum REPO width

The formatter SHALL preserve at least 4 characters of the REPO name before adding truncation indicator.

#### Scenario: REPO truncation format
- **WHEN** REPO is truncated
- **THEN** the displayed REPO SHALL be at least 4 characters followed by "..."
- **AND** the total REPO display width SHALL be at least 7 characters (4 + "...")

### Requirement: PR number never truncated

The formatter SHALL NOT truncate the PR number portion of the identifier.

#### Scenario: Number preserved in all truncation scenarios
- **WHEN** the identifier is truncated at any level
- **THEN** the full PR number SHALL be displayed after the "#" separator

### Requirement: Identifier truncation format

The truncated identifier SHALL maintain the standard format with visible separators.

#### Scenario: Truncated identifier structure
- **GIVEN** an identifier with ORG truncated to "abcd..." and REPO truncated to "efgh..."
- **WHEN** formatting the identifier
- **THEN** the output SHALL be "abcd.../efgh...#<number>"
