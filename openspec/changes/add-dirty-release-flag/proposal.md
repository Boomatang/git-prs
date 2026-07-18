## Why

The `zig build release` step enforces pre-flight checks (clean working directory, main branch, synced with origin) that prevent building release artifacts during development. A `--dirty` flag would allow developers to build release artifacts on any branch with uncommitted changes, useful for testing the release pipeline without committing work-in-progress.

## What Changes

- Add a `-Ddirty` build option to `build.zig` that skips the pre-flight checks in the `release` step.
- When `-Ddirty` is set, the release step skips: clean-tree check, main-branch check, origin-sync check, tag-exists check, and GitHub release-exists check.
- The `gh` CLI availability check is always performed regardless of the dirty flag.

## Capabilities

### New Capabilities

- `dirty-release-flag`: A `-Ddirty` build option that bypasses release pre-flight guards for local testing.

### Modified Capabilities

## Impact

- `build.zig`: Add build option and conditionally skip pre-flight shell command.
