## Context

The current build system (`build.zig`) supports:
- Building the native executable via `zig build`
- Running with `zig build run`
- Testing with `zig build test`

For release, we need cross-compiled binaries packaged as archives with checksums. Zig is a cross-compiler by design, making this straightforward from any host.

Current state:
- `build.zig.zon` contains `.name = .git_prs` and `.version = "0.0.0"`
- Executable is named `git_prs`
- No release artifact generation exists

## Goals / Non-Goals

**Goals:**
- Add `zig build artifacts` step that produces release-ready archives
- Cross-compile for 4 targets: linux-x86_64, linux-aarch64, macos-x86_64, macos-aarch64
- Generate `.tar.gz` archives with consistent naming
- Generate SHA256 checksums for verification
- Use `ReleaseSmall` for minimal binary size

**Non-Goals:**
- Windows support (not in initial release matrix)
- `.zip` archives (tar.gz only for now)
- Signing binaries
- Including additional files in archives (just binary for now)
- CI/CD integration (that's a separate concern)

## Decisions

### 1. Target definition approach

**Decision**: Define targets as a comptime array of `std.Target.Query` structs, iterate to create executables.

**Rationale**: Clean, declarative approach. Adding new targets is a one-line change. Zig's build system naturally parallelizes compilation across targets.

**Alternatives considered**:
- Separate build steps per target: More verbose, harder to maintain
- External script: Loses Zig build system benefits

### 2. Archive creation via tar command

**Decision**: Use `std.Build.Step.Run` to invoke the system `tar` command.

**Rationale**: Pragmatic solution. `tar` is universally available on Linux/macOS build hosts. Zig's stdlib has tar reading but limited writing support.

**Alternatives considered**:
- Pure Zig tar creation: More complex, std.tar is focused on reading
- External packaging tool: Unnecessary dependency

### 3. Checksum generation

**Decision**: Generate checksums using Zig's `std.crypto.hash.sha2.Sha256` and write `.sha256` files in `sha256sum` compatible format.

**Rationale**: No external dependency, consistent output format that users can verify with standard tools.

### 4. Output directory structure

**Decision**: Place all artifacts in `zig-out/artifacts/` flat directory.

**Rationale**: Simple, predictable location. Easy to upload entire directory for releases. Matches Zig convention of using `zig-out/` prefix.

### 5. Binary naming inside archive

**Decision**: Binary is named `git_prs` (from zon file, underscores preserved).

**Rationale**: Consistent with how the binary is installed locally. The archive name contains the target info, the binary itself is just `git_prs`.

## Risks / Trade-offs

**Risk**: `tar` command not available on build host
→ Mitigation: Document requirement; all target platforms (Linux/macOS) have tar by default

**Risk**: Cross-compilation fails for certain targets
→ Mitigation: Zig bundles libc for all targets; this should "just work"

**Trade-off**: Archives contain only the binary, no README/LICENSE
→ Acceptable for initial release; archive structure can be extended later
