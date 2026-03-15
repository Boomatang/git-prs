## Why

The current CLI implementation in `cli.zig` requires manual argument parsing with custom parsing functions for each command (`parseMineArgs`, `parseTeamArgs`, `parseMergedArgs`). This approach requires significant boilerplate code and ongoing maintenance as new commands and options are added. Adopting zig-clap allows us to focus on command behavior rather than parsing mechanics, with automatic help generation and a declarative API.

## What Changes

- Replace custom argument parsing in `cli.zig` with zig-clap declarative parameter definitions
- Remove manual help text generation in favor of zig-clap's automatic help system
- Add zig-clap as a build dependency via `build.zig.zon`
- Simplify command definitions using zig-clap's subcommand support
- Maintain all existing commands (`mine`, `team`, `merged`) and their options with identical behavior

## Capabilities

### New Capabilities

- `clap-integration`: Integration of zig-clap library for declarative CLI argument parsing with automatic help generation

### Modified Capabilities

- `cli-parser`: Reimplement argument parsing using zig-clap instead of manual parsing, maintaining all existing functionality

## Impact

- **Dependencies**: New dependency on zig-clap (added to `build.zig.zon`)
- **Code**: Major refactor of `src/cli.zig` to use zig-clap API
- **Build**: Updated `build.zig` to include zig-clap module
- **Tests**: CLI parsing tests will need updates to reflect new implementation approach
- **User-facing**: No change to CLI interface - all commands and options remain identical
