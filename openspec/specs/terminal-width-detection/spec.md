## ADDED Requirements

### Requirement: Detect terminal width via ioctl
The system SHALL query the terminal width using the TIOCGWINSZ ioctl on stdout before falling back to other methods.

#### Scenario: Standard terminal output
- **WHEN** output is directed to an interactive terminal
- **THEN** the table width SHALL match the actual terminal width

#### Scenario: Wide terminal display
- **WHEN** terminal width is 200 columns
- **THEN** the title column SHALL expand to use the additional space (200 minus fixed column widths)

#### Scenario: ioctl returns zero width
- **WHEN** ioctl succeeds but reports 0 columns
- **THEN** the system SHALL treat this as ioctl failure and check COLUMNS fallback

### Requirement: Graceful fallback for non-TTY output
The system SHALL fall back to 80 columns when terminal width cannot be determined via ioctl.

#### Scenario: Output piped to another command
- **WHEN** stdout is piped (e.g., `git-prs mine | grep foo`)
- **THEN** the table width SHALL default to 80 columns

#### Scenario: Output redirected to file
- **WHEN** stdout is redirected to a file (e.g., `git-prs mine > output.txt`)
- **THEN** the table width SHALL default to 80 columns

### Requirement: COLUMNS environment variable as secondary fallback
The system SHALL check the COLUMNS environment variable when ioctl fails, before defaulting to 80.

#### Scenario: COLUMNS set with piped output
- **WHEN** stdout is not a TTY AND COLUMNS environment variable is set to "120"
- **THEN** the table width SHALL be 120 columns

#### Scenario: Neither ioctl nor COLUMNS available
- **WHEN** stdout is not a TTY AND COLUMNS is not set
- **THEN** the table width SHALL default to 80 columns
