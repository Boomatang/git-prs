## ADDED Requirements

### Requirement: Header includes URL column in inline mode

The table header row SHALL include a "URL" column header when inline URL display mode is active.

#### Scenario: URL header shown in inline mode
- **WHEN** the terminal is wide enough for inline URL display
- **THEN** the header row SHALL end with "LAST  URL" instead of just "LAST"

#### Scenario: URL header not shown in two-line mode
- **WHEN** the terminal is not wide enough for inline URL display
- **THEN** the header row SHALL end with "LAST" without a URL column

### Requirement: Separator extends to URL column in inline mode

The header separator line SHALL extend to cover the full table width including the URL column when inline URL display mode is active.

#### Scenario: Separator covers URL column in inline mode
- **WHEN** the terminal is wide enough for inline URL display
- **THEN** the separator line SHALL extend to the end of the longest URL in the result set

#### Scenario: Separator unchanged in two-line mode
- **WHEN** the terminal is not wide enough for inline URL display
- **THEN** the separator line SHALL extend only to the LAST column (existing behavior)

### Requirement: Header and data rows align

The URL header column SHALL align with the URL data in the rows below.

#### Scenario: URL column alignment
- **WHEN** inline URL display mode is active
- **THEN** the "URL" header text SHALL start at the same position as the URLs in data rows
