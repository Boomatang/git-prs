## Context

The Zig 0.16.0 migration replaced `std.posix.isatty` with a raw `ioctl` call using `std.posix.T.CGETS`. This constant only exists on Linux — macOS uses `TIOCGETA` instead. The release build cross-compiles for `aarch64-macos` and `x86_64-macos`, which fail.

Zig 0.16.0 provides `std.Io.File.isTty(file, io)` which handles platform differences internally.

## Goals / Non-Goals

**Goals:**
- Fix cross-compilation for macOS targets so `zig build release` succeeds.
- Use the stdlib-provided `isTty` API instead of manual ioctl.

**Non-Goals:**
- Changing terminal width detection beyond what's needed for compilation.
- Adding new TTY-dependent features.

## Decisions

- **Use `std.Io.File.isTty(file, io)` instead of raw ioctl**: This is the API Zig 0.16.0 provides for cross-platform TTY detection. It handles Linux, macOS, and other targets internally. The alternative — adding conditional compilation for each platform's ioctl constant — would be fragile and redundant with what the stdlib already does.

- **Thread `io` into `isStdoutTty` and `getTerminalWidth`**: Both functions need `io` for the `isTty` call. The callers (`formatMineOutput`, `formatTeamOutput`) already receive `io` as a parameter, so this is just passing it one level deeper.

## Risks / Trade-offs

- `isTty` returns `Io.Cancelable!bool` (can error) whereas the current ioctl approach returns a plain `bool`. The callers should treat errors as "not a TTY" (safe fallback).
