## ADDED Requirements

### Requirement: Add zig-clap as build dependency
The build system SHALL include zig-clap as a dependency via `build.zig.zon`.

#### Scenario: Dependency available in build
- **WHEN** running `zig build`
- **THEN** the clap module is available for import in source files

### Requirement: Define mine command parameters with clap
The CLI SHALL define `mine` command parameters using zig-clap's declarative syntax.

#### Scenario: Mine parameter definition includes all options
- **WHEN** mine command parameters are defined
- **THEN** the definition includes `--org`, `--limit`, `--since`, `--until`, and `--json` options with correct types and defaults

### Requirement: Define team command parameters with clap
The CLI SHALL define `team` command parameters using zig-clap's declarative syntax.

#### Scenario: Team parameter definition includes all options
- **WHEN** team command parameters are defined
- **THEN** the definition includes positional team name, `--org`, `--member`, `--since`, `--until`, and `--json` options

### Requirement: Define merged command parameters with clap
The CLI SHALL define `merged` command parameters using zig-clap's declarative syntax.

#### Scenario: Merged parameter definition includes all options
- **WHEN** merged command parameters are defined
- **THEN** the definition includes `--days`, `--org`, `--since`, `--until`, and `--json` options

### Requirement: Generate help text automatically
The CLI SHALL use zig-clap's automatic help generation instead of manual help text.

#### Scenario: Help displays all commands
- **WHEN** user runs `git-prs --help`
- **THEN** help text displays all available commands with descriptions

#### Scenario: Help displays command options
- **WHEN** user runs `git-prs mine --help`
- **THEN** help text displays all options for the mine command with descriptions

### Requirement: Custom date parser for YYYY-MM-DD format
The CLI SHALL use a custom ap parser to validate date arguments in YYYY-MM-DD format.

#### Scenario: Valid date accepted
- **WHEN** user provides `--since 2025-01-15`
- **THEN** parser accepts the date value

#### Scenario: Invalid date format rejected
- **WHEN** user provides `--since 2025/01/15`
- **THEN** parser rejects with date format error
