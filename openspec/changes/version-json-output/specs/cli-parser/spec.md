## ADDED Requirements

### Requirement: Parse --version with --json flag
The CLI parser SHALL scan all arguments for `--version` flag before subcommand parsing, and check for `--json` flag when `--version` is found.

#### Scenario: Version flag alone
- **WHEN** args contain `--version` without `--json`
- **THEN** parser returns version command with json=false

#### Scenario: Version flag with --json
- **WHEN** args contain both `--version` and `--json` in any order
- **THEN** parser returns version command with json=true

#### Scenario: Version flag scanned before subcommand parsing
- **WHEN** args are `mine --version`
- **THEN** parser returns version command (not mine command)

#### Scenario: Version flag with json in subcommand context
- **WHEN** args are `team --json --version`
- **THEN** parser returns version command with json=true
