## Requirements

### Requirement: Version command supports JSON output
The version command SHALL output JSON when `--json` flag is present alongside `--version`.

#### Scenario: Version with --json flag
- **WHEN** user runs `git-prs --version --json`
- **THEN** output SHALL be `{"name":"git-prs","version":"0.1.0"}` (with actual version)

#### Scenario: Version with --json flag reversed order
- **WHEN** user runs `git-prs --json --version`
- **THEN** output SHALL be `{"name":"git-prs","version":"0.1.0"}` (with actual version)

#### Scenario: Version without --json flag
- **WHEN** user runs `git-prs --version`
- **THEN** output SHALL be plain text `git-prs 0.1.0` (unchanged behavior)

### Requirement: Version flag takes precedence
The `--version` flag SHALL take precedence over any subcommand when present anywhere in arguments.

#### Scenario: Version flag after subcommand
- **WHEN** user runs `git-prs mine --version`
- **THEN** output SHALL be plain text version (version takes precedence over mine)

#### Scenario: Version flag with subcommand and --json
- **WHEN** user runs `git-prs mine --json --version`
- **THEN** output SHALL be JSON version (version takes precedence, json applies)

#### Scenario: Version flag with other flags ignored
- **WHEN** user runs `git-prs team --org foo --version`
- **THEN** output SHALL be plain text version (other flags ignored)
