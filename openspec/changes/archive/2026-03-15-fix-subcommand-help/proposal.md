## Why

Running `git-prs mine --help` or `git-prs team --help` displays the top-level help instead of subcommand-specific help. The CLI has subcommand help functions (`printMineHelp`, `printTeamHelp`, `printMergedHelp`) but they're never called because the `Command.help` variant is `void` and carries no context about which subcommand triggered it.

## What Changes

- Add `HelpTarget` enum to track which command's help was requested (`main`, `mine`, `team`, `merged`)
- Change `Command.help` from `void` to `HelpTarget`
- Update subcommand parsers to return `.{ .help = .mine }`, `.{ .help = .team }`, `.{ .help = .merged }` instead of just `.help`
- Update `main.zig` to dispatch to the correct help function based on `HelpTarget`

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cli-parser`: Add requirement for subcommand-specific help output when `--help` is passed after a subcommand

## Impact

- `src/cli.zig`: Modify `Command` union, add `HelpTarget` enum, update parse functions
- `src/cli.zig` tests: Update tests that check for `.help` to use the new enum variant
- `src/main.zig`: Update help case in switch to dispatch based on `HelpTarget`
