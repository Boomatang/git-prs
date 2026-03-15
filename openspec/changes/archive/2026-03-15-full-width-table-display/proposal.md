## Why

The table display currently defaults to 80 columns because it reads terminal width from the `COLUMNS` environment variable, which is often not set or not exported to child processes. This causes titles to be truncated unnecessarily on wider terminals, wasting valuable screen space.

## What Changes

- Replace `COLUMNS` environment variable detection with direct terminal width detection using `ioctl` (TIOCGWINSZ) on POSIX systems
- Maintain fallback to 80 columns when terminal width cannot be determined (e.g., piped output, non-TTY)
- No changes to column layout logic - only the width detection mechanism changes

## Capabilities

### New Capabilities

- `terminal-width-detection`: Native terminal width detection using ioctl system call instead of relying on COLUMNS environment variable

### Modified Capabilities

(none - this change modifies implementation only, not requirements)

## Impact

- **Code**: `src/formatter.zig` - modify `getTerminalWidth()` function
- **Dependencies**: Uses existing `std.posix` for ioctl calls (no new dependencies)
- **Compatibility**: Linux/macOS (POSIX systems) - Windows would need separate handling if supported in future
