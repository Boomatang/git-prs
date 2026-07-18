# dirty-release-flag Specification

## Purpose
TBD - created by archiving change add-dirty-release-flag. Update Purpose after archive.
## Requirements
### Requirement: Dirty build option exists
The build system SHALL expose a `-Ddirty` boolean option (default `false`) that controls whether release pre-flight checks are enforced.

#### Scenario: Option appears in build help
- **WHEN** a user runs `zig build --help`
- **THEN** the output SHALL list `-Ddirty` with a description

### Requirement: Dirty flag skips pre-flight checks
When `-Ddirty=true` is passed, the release step SHALL skip all pre-flight guards: clean working directory, main branch, origin sync, tag existence, and GitHub release existence checks.

#### Scenario: Release build on non-main branch with dirty flag
- **WHEN** a user runs `zig build release -Ddirty` on a non-main branch
- **THEN** the build SHALL proceed past pre-flight checks and produce release artifacts

#### Scenario: Release build with uncommitted changes and dirty flag
- **WHEN** a user runs `zig build release -Ddirty` with uncommitted changes in the working directory
- **THEN** the build SHALL proceed past pre-flight checks and produce release artifacts

### Requirement: Default behavior unchanged
When `-Ddirty` is not passed (or is `false`), the release step SHALL enforce all existing pre-flight checks.

#### Scenario: Release build without dirty flag enforces guards
- **WHEN** a user runs `zig build release` without `-Ddirty` on a non-main branch
- **THEN** the build SHALL fail with the existing "Must be on main branch" error

