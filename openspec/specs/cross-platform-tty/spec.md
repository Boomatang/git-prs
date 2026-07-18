# cross-platform-tty Specification

## Purpose
TBD - created by archiving change fix-cross-platform-tty. Update Purpose after archive.
## Requirements
### Requirement: TTY detection uses cross-platform stdlib API
The `isStdoutTty` function SHALL use `std.Io.File.isTty(file, io)` for terminal detection instead of platform-specific ioctl constants.

#### Scenario: Compiles for Linux target
- **WHEN** `zig build` targets `x86_64-linux`
- **THEN** compilation SHALL succeed without errors in `formatter.zig`

#### Scenario: Compiles for macOS aarch64 target
- **WHEN** `zig build release` cross-compiles for `aarch64-macos`
- **THEN** compilation SHALL succeed without errors in `formatter.zig`

#### Scenario: Compiles for macOS x86_64 target
- **WHEN** `zig build release` cross-compiles for `x86_64-macos`
- **THEN** compilation SHALL succeed without errors in `formatter.zig`

#### Scenario: TTY detection error falls back to non-TTY
- **WHEN** `isTty` returns an error
- **THEN** the function SHALL return `false` (treat as non-TTY)

### Requirement: io parameter threaded to TTY-dependent functions
Functions that perform TTY detection SHALL accept an `io: std.Io` parameter to support the stdlib API.

#### Scenario: isStdoutTty accepts io parameter
- **WHEN** `isStdoutTty` is called
- **THEN** it SHALL accept `io: std.Io` as a parameter

#### Scenario: getTerminalWidth accepts io parameter
- **WHEN** `getTerminalWidth` is called
- **THEN** it SHALL accept `io: std.Io` as a parameter

