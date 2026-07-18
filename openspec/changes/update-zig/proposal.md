## Why

Zig 0.16.0 introduces breaking API changes to the standard library (new `main` function signature, `std.Io` namespace, allocator initialization). The project needs to stay on a supported Zig version to continue receiving bug fixes and to keep dependencies (like zig-clap) compatible.

## What Changes

- **BREAKING**: Bump minimum Zig version from 0.15.2 to 0.16.0
- Update `zig-clap` dependency from 0.11.0 to 0.12.0 (required for Zig 0.16.0 compatibility)
- Adapt `main` function signature to use `std.process.Init` parameter instead of manual `GeneralPurposeAllocator` setup
- Migrate `std.fs.File.stderr()`/`stdout()` to `std.Io.File.stderr()`/`stdout()`
- Remove boilerplate comments from `build.zig` and `build.zig.zon` (Zig 0.16.0 project template cleanup)
- Add `zig-pkg/` to `.gitignore`

## Capabilities

### New Capabilities

_None — this is a toolchain update, not a feature change._

### Modified Capabilities

_None — no spec-level behavior changes. All modifications are internal build/runtime adaptations._

## Impact

- **Build system**: `build.zig` and `build.zig.zon` updated for new Zig APIs and dependency hashes
- **Entry point**: `src/main.zig` — new function signature and stdlib API calls
- **Dependencies**: `zig-clap` 0.11.0 → 0.12.0
- **Developer environment**: Requires Zig 0.16.0 installed locally
