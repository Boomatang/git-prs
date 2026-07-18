## 1. Build Configuration

- [x] 1.1 Update `minimum_zig_version` to `"0.16.0"` in `build.zig.zon`
- [x] 1.2 Update `zig-clap` dependency URL and hash from 0.11.0 to 0.12.0 in `build.zig.zon`
- [x] 1.3 Remove boilerplate comments from `build.zig.zon`
- [x] 1.4 Remove boilerplate comments from `build.zig`
- [x] 1.5 Add `zig-pkg/` to `.gitignore`

## 2. Source Code Migration

- [x] 2.1 Update `main` function signature in `src/main.zig` to accept `std.process.Init` parameter
- [x] 2.2 Replace `GeneralPurposeAllocator` setup with `init.gpa` in `src/main.zig`
- [x] 2.3 Migrate `std.fs.File.stderr()`/`stdout()` to `std.Io.File.stderr()`/`stdout()` in `src/main.zig`
- [x] 2.4 Audit `src/root.zig` and other source files for additional `std.fs.File` or deprecated API usages

## 3. Verification

- [x] 3.1 Run `zig build` and confirm successful compilation
- [x] 3.2 Run `zig build test` and confirm all tests pass
