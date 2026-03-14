## Why

As the tool approaches its first release, we need a streamlined way to create GitHub releases locally. Currently `zig build artifacts` creates cross-compiled binaries, but there's no automation for version checking, tagging, and uploading to GitHub.

## What Changes

- Add `zig build release` step that orchestrates the full release workflow
- Pre-flight checks ensure release safety:
  - `gh` CLI must be available
  - Working directory must be clean
  - Must be on main branch
  - Local and remote must be in sync
  - Version must not already be released
- Clean artifacts directory before building
- Build all release artifacts (reuses existing cross-compilation logic)
- Create draft GitHub release with artifacts attached via `gh release create`

## Capabilities

### New Capabilities

- `release-build-step`: Build step that validates release conditions, builds artifacts, and creates a draft GitHub release

### Modified Capabilities

## Impact

- `build.zig`: Add new `release` step with pre-flight checks, clean step, artifact building, and gh release creation
- Requires `gh` CLI installed on the release machine
- No changes to existing `artifacts` step (remains independent for dev testing)
