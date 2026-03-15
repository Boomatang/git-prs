## Why

The `--json` flag works on `mine`, `team`, and `merged` commands but not on `--version`. For CLI consistency, all common flags should behave the same across all commands.

## What Changes

- `--version` flag gains support for `--json` modifier
- When both flags are present (in any order), output JSON: `{"name":"git-prs","version":"0.1.0"}`
- `--version` takes precedence anywhere in args (e.g., `mine --version` shows version)
- Works with any argument order: `--version --json`, `--json --version`, `mine --json --version`

## Capabilities

### New Capabilities

- `version-json-output`: JSON output support for the version command, allowing `--version --json` to output structured version information

### Modified Capabilities

- `cli-parser`: Version flag parsing changes to scan all args for `--version` first, then check for `--json`, supporting version flag anywhere in argument list

## Impact

- `src/cli.zig`: Parsing logic for `--version` changes to check all args and support `--json` flag
- `src/main.zig`: Version output handler needs to support JSON format
- Existing `--version` behavior (plain text) unchanged when `--json` not present
