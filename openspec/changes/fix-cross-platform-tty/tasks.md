## 1. Fix TTY Detection

- [x] 1.1 Replace `isStdoutTty()` in `src/formatter.zig` to use `std.Io.File.isTty(file, io)` with `io: std.Io` parameter, treating errors as non-TTY
- [x] 1.2 Update `getTerminalWidth()` in `src/formatter.zig` to accept `io: std.Io` and pass it to `isStdoutTty`
- [x] 1.3 Update `formatMineOutput` and `formatTeamOutput` to pass `io` to `getTerminalWidth`

## 2. Verification

- [x] 2.1 Run `zig build` and confirm native compilation succeeds
- [x] 2.2 Run `zig build test` and confirm all tests pass
- [x] 2.3 Run `zig build release` and confirm cross-compilation for macOS targets succeeds
