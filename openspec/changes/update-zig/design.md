## Context

The project currently targets Zig 0.15.2. Zig 0.16.0 introduces breaking changes to the standard library API surface — notably the `main` function signature, I/O namespace reorganization (`std.fs.File` → `std.Io.File`), and allocator initialization via `std.process.Init`. The `zig-clap` dependency also requires a version bump (0.11.0 → 0.12.0) for compatibility.

Most of the diff is comment removal — Zig 0.16.0's project template no longer includes the verbose boilerplate comments in `build.zig` and `build.zig.zon`.

## Goals / Non-Goals

**Goals:**
- Compile and run correctly on Zig 0.16.0
- Update all dependencies to their Zig 0.16.0-compatible versions
- Clean up build files to match current Zig conventions

**Non-Goals:**
- Adopting any new Zig 0.16.0 features beyond what's required for compatibility
- Refactoring application logic
- Supporting both Zig 0.15.x and 0.16.0 simultaneously

## Decisions

**1. Update `main` signature to use `std.process.Init`**
Zig 0.16.0 replaces the convention of manually creating a `GeneralPurposeAllocator` in `main` with a structured `Init` parameter that provides `init.gpa`. This is the idiomatic approach and avoids deprecation warnings.

Alternative: Keep `GeneralPurposeAllocator` manually — rejected because 0.16.0 expects the new signature.

**2. Migrate I/O from `std.fs.File` to `std.Io.File`**
The stderr/stdout accessors moved from `std.fs.File` to `std.Io.File` in 0.16.0. Straightforward namespace change.

**3. Bump zig-clap from 0.11.0 to 0.12.0**
Required for Zig 0.16.0 compatibility. The clap API surface used by this project is stable across this bump.

**4. Remove boilerplate comments from build files**
Zig 0.16.0's default template no longer includes these tutorial-style comments. Removing them reduces noise and aligns with upstream conventions.

## Risks / Trade-offs

**[Risk] Other `std.fs.File` or `std.Io` usages in `src/root.zig` or library code** → Audit all source files for additional API migration points beyond `src/main.zig`.

**[Risk] zig-clap 0.12.0 API changes** → Verify clap usage still compiles. The project uses standard argument parsing which is stable across versions.

**[Trade-off] No dual-version support** → Developers must use Zig 0.16.0. Acceptable for a small project with a single maintainer.
