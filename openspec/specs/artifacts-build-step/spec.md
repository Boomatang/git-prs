## ADDED Requirements

### Requirement: Artifacts build step exists

The build system SHALL provide an `artifacts` step invoked via `zig build artifacts`.

#### Scenario: Running artifacts step

- **WHEN** user runs `zig build artifacts`
- **THEN** the system builds release artifacts for all supported targets

### Requirement: Cross-compilation targets

The artifacts step SHALL cross-compile for the following targets:
- `x86_64-linux`
- `aarch64-linux`
- `x86_64-macos`
- `aarch64-macos`

#### Scenario: All targets built

- **WHEN** `zig build artifacts` completes successfully
- **THEN** archives exist for all 4 targets in `zig-out/artifacts/`

### Requirement: ReleaseSmall optimization

The artifacts step SHALL compile all binaries with `ReleaseSmall` optimization.

#### Scenario: Small binary size

- **WHEN** artifacts are built
- **THEN** binaries are optimized for minimal size

### Requirement: Archive format and naming

Each target SHALL produce a `.tar.gz` archive named `{name}-{version}-{os}-{arch}.tar.gz` where:
- `{name}` is derived from `build.zig.zon` (displayed as `git_prs`)
- `{version}` is from `build.zig.zon`
- `{os}` is `linux` or `macos`
- `{arch}` is `x86_64` or `aarch64`

#### Scenario: Archive naming

- **WHEN** version is `1.0.0` and target is `x86_64-linux`
- **THEN** archive is named `git_prs-1.0.0-linux-x86_64.tar.gz`

### Requirement: Archive contents

Each archive SHALL contain the binary named `git_prs`.

#### Scenario: Binary inside archive

- **WHEN** archive is extracted
- **THEN** it contains a single executable named `git_prs`

### Requirement: Checksum generation

For each archive, the system SHALL generate a `.sha256` checksum file in `sha256sum` compatible format.

#### Scenario: Checksum file format

- **WHEN** archive `git_prs-1.0.0-linux-x86_64.tar.gz` is created
- **THEN** `git_prs-1.0.0-linux-x86_64.tar.gz.sha256` is created containing `<hash>  git_prs-1.0.0-linux-x86_64.tar.gz`

#### Scenario: Checksum verification

- **WHEN** user runs `sha256sum -c *.sha256` in artifacts directory
- **THEN** all checksums verify successfully

### Requirement: Output directory

All artifacts SHALL be placed in `zig-out/artifacts/`.

#### Scenario: Artifacts location

- **WHEN** `zig build artifacts` completes
- **THEN** all `.tar.gz` and `.sha256` files are in `zig-out/artifacts/`
