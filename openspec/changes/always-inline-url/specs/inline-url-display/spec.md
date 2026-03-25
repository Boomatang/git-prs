## ADDED Requirements

(none)

## MODIFIED Requirements

### Requirement: Inline URL display when terminal is wide enough

The system SHALL display the PR URL on the same line as the PR data regardless of terminal width.

#### Scenario: Wide terminal shows URL inline for mine view
- **GIVEN** a terminal width of W columns
- **AND** fixed columns (identifier + spacing + AGE + 👤 + LAST) require F columns
- **AND** the PR URL has length U characters
- **WHEN** formatting a PR row
- **THEN** the URL SHALL be displayed at the end of the row, separated by 2 spaces from the LAST column
- **AND** other columns SHALL truncate as needed to accommodate the URL

#### Scenario: Wide terminal shows URL inline for team view
- **GIVEN** a terminal width of W columns
- **AND** fixed columns (AUTHOR + identifier + spacing + AGE + 👤 + LAST) require F columns
- **AND** the PR URL has length U characters
- **WHEN** formatting a PR row
- **THEN** the URL SHALL be displayed at the end of the row, separated by 2 spaces from the LAST column
- **AND** other columns SHALL truncate as needed to accommodate the URL

#### Scenario: Narrow terminal still shows URL inline
- **GIVEN** a narrow terminal width
- **WHEN** formatting a PR row
- **THEN** the URL SHALL still be displayed inline at the end of the row
- **AND** flexible columns (title, author, identifier) SHALL truncate to minimum widths
- **AND** the row MAY extend beyond terminal width, relying on natural line wrapping

### Requirement: URL never truncated

The system SHALL NOT truncate URLs.

#### Scenario: Full URL always displayed inline
- **WHEN** displaying a PR with any terminal width
- **THEN** the complete URL SHALL be displayed without truncation
- **AND** the URL MAY extend beyond terminal width (relying on terminal wrapping)

### Requirement: Header always includes URL column

The system SHALL always display the URL column header regardless of terminal width.

#### Scenario: URL header in mine view
- **WHEN** formatting mine output header
- **THEN** the header SHALL include "URL" as the final column

#### Scenario: URL header in team view
- **WHEN** formatting team output header
- **THEN** the header SHALL include "URL" as the final column

### Requirement: JSON output unchanged

The system SHALL NOT modify JSON output format.

#### Scenario: JSON output unaffected
- **WHEN** using --json flag
- **THEN** output format SHALL remain unchanged from current behavior

## REMOVED Requirements

### Requirement: Two-line URL display when terminal is narrow

**Reason**: Replaced by always-inline display with column truncation. Users prefer consistent single-line format with truncated columns over URL on separate line.

**Migration**: No migration needed. Output format changes automatically; URL always appears inline.

### Requirement: Per-row format decision

**Reason**: No longer applicable since all rows use inline format.

**Migration**: No migration needed. All rows now use consistent inline format.

### Requirement: Minimum title width preserved

**Reason**: Replaced by cascading truncation priority. Title can now shrink below 20 characters to accommodate URL.

**Migration**: No migration needed. Title may display shorter on narrow terminals.
