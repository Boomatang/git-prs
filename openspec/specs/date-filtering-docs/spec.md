## ADDED Requirements

### Requirement: Date filtering options documented for mine command

The cli-reference.md mine command section SHALL document `--since` and `--until` options.

#### Scenario: User reads mine command date filtering options
- **WHEN** a user reads the mine command options in cli-reference.md
- **THEN** they find `--since <YYYY-MM-DD>` described as filtering to PRs created on or after the date
- **THEN** they find `--until <YYYY-MM-DD>` described as filtering to PRs created on or before the date

### Requirement: Date filtering options documented for team command

The cli-reference.md team command section SHALL document `--since` and `--until` options.

#### Scenario: User reads team command date filtering options
- **WHEN** a user reads the team command options in cli-reference.md
- **THEN** they find `--since <YYYY-MM-DD>` described as filtering to PRs created on or after the date
- **THEN** they find `--until <YYYY-MM-DD>` described as filtering to PRs created on or before the date
- **THEN** the documentation notes that CLI options override config file date settings

### Requirement: Date filtering examples provided

The cli-reference.md examples section SHALL include date filtering examples.

#### Scenario: User finds date filtering examples
- **WHEN** a user looks at the Examples section
- **THEN** they find at least one example showing `--since` usage
- **THEN** they find at least one example showing combined `--since` and `--until` for a date range

### Requirement: Date filtering mentioned in README

The README.md features list SHALL mention date filtering capability.

#### Scenario: User discovers date filtering in README
- **WHEN** a user reads the README.md Features section
- **THEN** they see a mention of filtering PRs by date
