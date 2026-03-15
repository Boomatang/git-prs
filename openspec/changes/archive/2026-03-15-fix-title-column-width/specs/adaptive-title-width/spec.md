## ADDED Requirements

### Requirement: Title column width adapts to content

The formatter SHALL size the title column based on the longest PR title in the result set, rather than filling all available terminal width.

#### Scenario: Short titles use narrow column
- **WHEN** all PR titles are 30 characters or less
- **AND** terminal width is 120 characters
- **THEN** the title column width SHALL be approximately 32 characters (longest title + 2 margin)
- **AND** the title column SHALL NOT expand to fill remaining terminal width

#### Scenario: Long titles use available width
- **WHEN** the longest PR title exceeds available terminal width minus fixed columns
- **THEN** the title column width SHALL equal available terminal width minus fixed columns
- **AND** long titles SHALL be truncated with "..." suffix

### Requirement: Minimum title width preserved

The formatter SHALL maintain a minimum title width of 20 characters regardless of actual title lengths.

#### Scenario: Very short titles maintain minimum width
- **WHEN** all PR titles are 10 characters or less
- **THEN** the title column width SHALL be at least 20 characters

### Requirement: Title width includes margin

The formatter SHALL add a 2-character margin to the calculated maximum title length for visual spacing.

#### Scenario: Margin added to title width
- **WHEN** the longest PR title is 25 characters
- **AND** terminal width is sufficient
- **THEN** the title column width SHALL be 27 characters (25 + 2 margin)

### Requirement: Consistent column width across rows

All PR rows in a single output SHALL use the same title column width.

#### Scenario: Mixed title lengths use uniform width
- **WHEN** PR titles range from 10 to 40 characters
- **THEN** all rows SHALL use the same title column width (42 characters: 40 + 2 margin)
- **AND** shorter titles SHALL be padded with spaces to match column width
