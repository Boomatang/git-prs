## Why

As the tool approaches release, users need a standard way to identify which version they're running. This is essential for troubleshooting, bug reports, and ensuring compatibility. The `--version` flag is a ubiquitous CLI convention.

## What Changes

- Add `--version` top-level flag to the CLI (similar to `--help`)
- Version and name are read from `build.zig.zon` at compile time and injected as build options
- Output format: `git-prs X.Y.Z`

## Capabilities

### New Capabilities

- `version-flag`: CLI flag that displays the tool name and version, sourced from build.zig.zon at compile time

### Modified Capabilities

## Impact

- `build.zig`: Add build options to extract and pass version/name from zon file
- `src/cli.zig`: Add `version` variant to Command union, handle `--version` in parseArgs
- `src/main.zig`: Handle version command to print output and exit
