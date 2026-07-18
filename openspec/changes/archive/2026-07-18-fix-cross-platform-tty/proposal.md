## Why

The `isStdoutTty()` function in `src/formatter.zig` uses `std.posix.T.CGETS` (Linux-specific ioctl) to detect terminal status. This fails to compile when cross-compiling for macOS targets (`aarch64-macos`, `x86_64-macos`), breaking `zig build release` which produces binaries for all supported platforms.

## What Changes

- Replace the Linux-specific raw ioctl TTY detection with the cross-platform `std.Io.File.isTty(file, io)` API provided by Zig 0.16.0's stdlib.
- Thread `io: std.Io` into `isStdoutTty` and its callers (`getTerminalWidth`, `formatMineOutput`, `formatTeamOutput`) where not already available.

## Capabilities

### New Capabilities

- `cross-platform-tty`: Replace platform-specific TTY detection with Zig stdlib's cross-platform `Io.File.isTty()` API.

### Modified Capabilities

## Impact

- `src/formatter.zig`: `isStdoutTty()`, `getTerminalWidth()`, and the format output functions that call them.
- `src/main.zig`: May need to pass `io` to additional call sites if not already threaded through.
- Release build: Currently broken for macOS targets; this fix unblocks cross-compilation.
