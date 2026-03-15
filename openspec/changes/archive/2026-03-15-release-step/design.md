## Context

The project has an existing `zig build artifacts` step that cross-compiles for 4 targets (linux-x86_64, linux-aarch64, macos-x86_64, macos-aarch64) and creates .tar.gz archives with .sha256 checksums. The version is sourced from `build.zig.zon`.

Currently there's no automation for the release workflow - creating tags, validating release conditions, or uploading to GitHub. The `gh` CLI is the standard tool for GitHub operations.

## Goals / Non-Goals

**Goals:**
- Single command (`zig build release`) to create a draft GitHub release
- Fail fast with clear error messages if release conditions aren't met
- Keep `zig build artifacts` independent for development/testing use
- Let `gh release create` handle tag creation on remote

**Non-Goals:**
- CI/CD integration (local-only for now)
- Automatic version bumping (user manages version in build.zig.zon)
- Automatic pushing of commits (user controls when to push)
- Publishing releases (creates draft only)

## Decisions

### 1. Separate step from artifacts

The `release` step will have its own artifact build chain rather than depending on `artifacts_step`. This allows release to inject pre-flight checks and cleaning before building, without affecting the standalone `artifacts` command.

**Alternative considered**: Make `artifacts` depend on optional clean/check steps. Rejected because it complicates the dependency graph and affects standalone artifact builds.

### 2. Single pre-flight script

All pre-flight checks run in a single shell script that fails fast on first error. This provides clear, sequential error messages and simpler dependency management.

**Checks in order**:
1. `gh` CLI available
2. Working directory clean
3. On main branch
4. Local HEAD matches origin/main
5. Version tag doesn't exist locally or remotely

### 3. Let gh create the tag

Instead of creating a local git tag and pushing it, let `gh release create` handle tag creation on remote. This simplifies the workflow and avoids the need to push tags separately.

User syncs local tags afterward with `git fetch --tags` if needed.

### 4. Draft release only

Always create draft releases. This allows the user to:
- Review auto-generated release notes
- Edit the description before publishing
- Verify artifacts before making public

## Risks / Trade-offs

**[Code duplication]** The release step duplicates the artifact build loop from artifacts step.
→ Acceptable for now; keeps steps independent. Could extract shared function later if maintenance becomes an issue.

**[gh CLI dependency]** Requires gh CLI installed and authenticated.
→ Hard fail with clear error message. This is a reasonable requirement for release workflow.

**[No local tag]** After release, local repo won't have the tag until user fetches.
→ Documented behavior. User runs `git fetch --tags` to sync.

**[Race condition]** Someone could create a release between our check and `gh release create`.
→ Unlikely for single-maintainer project. `gh release create` will fail if tag exists, providing a second check.
