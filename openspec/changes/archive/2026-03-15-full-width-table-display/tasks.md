## 1. Core Implementation

- [x] 1.1 Implement ioctl-based terminal width detection using `std.posix.winsize` and `std.posix.T.IOCGWINSZ` (treat 0 as failure)
- [x] 1.2 Add COLUMNS env var fallback when ioctl fails
- [x] 1.3 Maintain 80-column default as final fallback

## 2. Testing

- [x] 2.1 Add test for ioctl-based width detection (when running in terminal)
- [x] 2.2 Add test for COLUMNS fallback behavior
- [x] 2.3 Run existing formatter tests to verify no regressions
- [x] 2.4 Manual test: verify table uses full terminal width

## 3. Verification

- [x] 3.1 Build and run `zig build`
- [x] 3.2 Run `./zig-out/bin/git-prs mine` and verify output spans terminal width
