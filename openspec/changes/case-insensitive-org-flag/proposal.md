## Why

The `--org` flag requires exact case matching, so `--org kubernetes` won't match a configured org "Kubernetes". This creates friction when users don't remember the exact casing of org names in their config.

## What Changes

- The `--org` flag value will be compared case-insensitively against configured org names
- Both `mine` and `team` commands will use case-insensitive matching
- The original casing from the config is preserved for API calls and display

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cli-parser`: No changes needed - stores the user's input as-is
- `github-client`: Modify org filter comparison to use case-insensitive matching
- The team command org lookup in main.zig needs case-insensitive matching against config keys

## Impact

- `src/github.zig`: Change `std.mem.eql` to case-insensitive comparison in `fetchUserPRs`
- `src/main.zig`: Change team org lookup to use case-insensitive key matching
- No breaking changes - existing exact-case usage still works
- No config file changes required
