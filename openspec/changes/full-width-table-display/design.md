## Context

The current `getTerminalWidth()` function in `src/formatter.zig` reads the `COLUMNS` environment variable to determine terminal width, defaulting to 80 if not set. However, `COLUMNS` is a shell variable that is often not exported to child processes, causing the table display to use 80 columns even on wider terminals.

The Zig standard library provides access to POSIX ioctl calls through `std.posix`, which can query the actual terminal dimensions.

## Goals / Non-Goals

**Goals:**
- Detect actual terminal width using ioctl TIOCGWINSZ
- Maintain 80-column fallback for non-TTY output (pipes, redirects)
- Keep existing column layout and calculation logic unchanged

**Non-Goals:**
- Windows terminal support (can be added later if needed)
- Dynamic resize handling (terminal width is checked once at render time)
- Changing column proportions or layout

## Decisions

### 1. Use ioctl with TIOCGWINSZ for width detection

**Decision**: Query terminal dimensions via `std.posix.system.ioctl(handle, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize))` using the built-in `std.posix.winsize` struct.

**Rationale**: This is the standard POSIX approach and works regardless of whether `COLUMNS` is exported. It's what tools like `ls`, `grep`, and other CLI utilities use. Zig's standard library provides the necessary types and constants.

**Alternatives considered**:
- Keep `COLUMNS` as primary, add ioctl as fallback: Still fails when COLUMNS is set incorrectly
- Use `stty size`: Requires spawning external process, adds complexity
- Use external library (zig-termsize): Adds unnecessary dependency for a simple operation

### 2. Query stdout file descriptor

**Decision**: Use `std.io.getStdOut().handle` for the ioctl call.

**Rationale**: The table output goes to stdout, so its dimensions are what matter. If stdout is redirected to a file, ioctl will fail and we correctly fall back to 80 columns.

### 3. Maintain COLUMNS as secondary fallback

**Decision**: If ioctl fails (non-TTY), check `COLUMNS` env var before defaulting to 80.

**Rationale**: Preserves compatibility for users who explicitly set `COLUMNS` for piped output.

## Risks / Trade-offs

**[Risk]** ioctl may behave differently across Unix variants → Mitigation: Using standard TIOCGWINSZ which is consistent across Linux, macOS, and BSDs.

**[Risk]** Potential for very wide output on ultra-wide monitors → Mitigation: Existing column layout naturally handles this; title column expands while fixed columns stay fixed. Could add max width cap later if needed.

**[Trade-off]** Direct syscall is slightly more complex than env var read → Accepted because it solves the core problem reliably.
