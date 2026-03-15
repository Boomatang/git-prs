## Why

As the tool approaches release, we need a reproducible way to build release binaries for distribution. Users on different platforms need pre-built binaries, and releases need checksums for verification.

## What Changes

- Add `zig build artifacts` step that cross-compiles for all supported targets
- Generate `.tar.gz` archives for each target with the binary inside
- Generate `.sha256` checksum files for each archive
- Output all artifacts to `zig-out/artifacts/`
- Use `ReleaseSmall` optimization by default for minimal binary size

Target matrix (4 targets):
- linux-x86_64
- linux-aarch64
- macos-x86_64
- macos-aarch64

Archive naming: `git_prs-{version}-{os}-{arch}.tar.gz`
Binary inside archive: `git_prs` (name from zon file)

## Capabilities

### New Capabilities

- `artifacts-build-step`: Build step that cross-compiles, archives, and generates checksums for all release targets

### Modified Capabilities

## Impact

- `build.zig`: Add new `artifacts` step with target iteration, archive creation, and checksum generation
- Requires `tar` command available on the build host
- Version and name sourced from `build.zig.zon`
