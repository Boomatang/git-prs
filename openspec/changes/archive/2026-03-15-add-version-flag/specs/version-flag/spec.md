## ADDED Requirements

### Requirement: Version flag displays name and version

The CLI SHALL support a `--version` flag that prints the tool name and version number.

The output format SHALL be `<name> <version>` where:
- `<name>` is the tool name derived from `build.zig.zon` (displayed as `git-prs`)
- `<version>` is the semantic version from `build.zig.zon`

#### Scenario: User runs --version

- **WHEN** user runs `git_prs --version`
- **THEN** the CLI prints `git-prs <version>` to stdout and exits with code 0

#### Scenario: Version flag takes precedence

- **WHEN** user runs `git_prs --version` with other arguments
- **THEN** the CLI prints version information and exits (other arguments are ignored)

### Requirement: Version sourced from build.zig.zon

The version and name SHALL be extracted from `build.zig.zon` at compile time and injected as build options.

The zon file SHALL NOT be embedded in the binary.

#### Scenario: Version matches zon file

- **WHEN** `build.zig.zon` contains `.version = "1.2.3"`
- **THEN** `git_prs --version` outputs `git-prs 1.2.3`

### Requirement: Version flag is top-level

The `--version` flag SHALL be parsed at the top level, before command parsing, matching the behavior of `--help`.

#### Scenario: Version without subcommand

- **WHEN** user runs `git_prs --version` without a subcommand
- **THEN** version is displayed (no "unknown command" error)
