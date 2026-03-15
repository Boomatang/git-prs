## ADDED Requirements

### Requirement: Inline URL display when terminal is wide enough

The system SHALL display the PR URL on the same line as the PR data when the terminal width allows at least 20 characters for the title after accounting for all fixed columns and the URL.

#### Scenario: Wide terminal shows URL inline for mine view
- **GIVEN** a terminal width of W columns
- **AND** fixed columns (identifier + spacing + AGE + 👤 + LAST) require F columns
- **AND** the PR URL has length U characters
- **WHEN** W - F - U - 2 >= 20 (leaving at least 20 chars for title)
- **THEN** the URL SHALL be displayed at the end of the row, separated by 2 spaces from the LAST column
- **AND** the title width SHALL be W - F - U - 2 (reduced to make room for URL)

#### Scenario: Wide terminal shows URL inline for team view
- **GIVEN** a terminal width of W columns
- **AND** fixed columns (AUTHOR + identifier + spacing + AGE + 👤 + LAST) require F columns
- **AND** the PR URL has length U characters
- **WHEN** W - F - U - 2 >= 20 (leaving at least 20 chars for title)
- **THEN** the URL SHALL be displayed at the end of the row, separated by 2 spaces from the LAST column
- **AND** the title width SHALL be W - F - U - 2 (reduced to make room for URL)

### Requirement: Two-line URL display when terminal is narrow

The system SHALL display the PR URL on a separate indented line when inline display would leave fewer than 20 characters for the title.

#### Scenario: Narrow terminal shows URL on separate line for mine view
- **GIVEN** a terminal width of W columns
- **AND** fixed columns require F columns
- **AND** the PR URL has length U characters
- **WHEN** W - F - U - 2 < 20 (insufficient space for title)
- **THEN** the URL SHALL be displayed on a second line with 4-space indentation
- **AND** the title width SHALL be W - F (full available width)

#### Scenario: Narrow terminal shows URL on separate line for team view
- **GIVEN** a terminal width of W columns
- **AND** fixed columns require F columns
- **AND** the PR URL has length U characters
- **WHEN** W - F - U - 2 < 20 (insufficient space for title)
- **THEN** the URL SHALL be displayed on a second line with 4-space indentation
- **AND** the title width SHALL be W - F (full available width)

### Requirement: Minimum title width preserved

The system SHALL ensure titles have at least 20 characters of display width regardless of URL display mode.

#### Scenario: Title width never below minimum
- **GIVEN** any terminal width and URL length combination
- **WHEN** formatting a PR row
- **THEN** the title column SHALL have at least 20 characters width

### Requirement: URL never truncated

The system SHALL NOT truncate URLs in either display mode.

#### Scenario: Full URL always displayed inline
- **WHEN** displaying a PR with inline URL format
- **THEN** the complete URL SHALL be displayed without truncation

#### Scenario: Full URL always displayed on separate line
- **WHEN** displaying a PR with two-line URL format
- **THEN** the complete URL SHALL be displayed without truncation
- **AND** the URL MAY extend beyond terminal width (relying on terminal wrapping)

### Requirement: Per-row format decision

The system SHALL calculate inline eligibility independently for each PR row, allowing mixed formats within a single output when URL lengths vary.

#### Scenario: Mixed format output with varying URL lengths
- **GIVEN** multiple PRs with different URL lengths
- **AND** a terminal width that allows some URLs inline but not others
- **WHEN** formatting the output
- **THEN** each row SHALL independently use inline or two-line format based on its own URL length

### Requirement: JSON output unchanged

The system SHALL NOT modify JSON output format.

#### Scenario: JSON output unaffected
- **WHEN** using --json flag
- **THEN** output format SHALL remain unchanged from current behavior
