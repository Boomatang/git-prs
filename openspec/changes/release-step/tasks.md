## 1. Pre-flight Checks

- [x] 1.1 Add pre-flight check shell command that verifies gh CLI is available
- [x] 1.2 Add check that working directory is clean (git status --porcelain)
- [x] 1.3 Add check that current branch is main
- [x] 1.4 Add check that local HEAD matches origin/main (after git fetch)
- [x] 1.5 Add check that version tag doesn't exist locally (git tag -l)
- [x] 1.6 Add check that GitHub release doesn't exist (gh release view)

## 2. Release Step Structure

- [x] 2.1 Create top-level "release" step with description "Create a GitHub release"
- [x] 2.2 Add clean command to remove zig-out/artifacts/ directory
- [x] 2.3 Chain clean step to depend on pre-flight checks

## 3. Artifact Building for Release

- [x] 3.1 Add artifact build loop for release step (same 4 targets as artifacts step)
- [x] 3.2 Chain artifact mkdir commands to depend on clean step
- [x] 3.3 Verify artifacts use version from build.zig.zon in archive names

## 4. GitHub Release Creation

- [x] 4.1 Add gh release create command with --draft flag
- [x] 4.2 Set release title to "git-prs v{version}"
- [x] 4.3 Add --generate-notes flag for auto-generated release notes
- [x] 4.4 Attach all .tar.gz and .sha256 files from zig-out/artifacts/
- [x] 4.5 Chain gh release command to depend on all artifact builds completing

## 5. Verification

- [x] 5.1 Test zig build release fails when gh is not available
- [x] 5.2 Test zig build release fails with dirty working directory
- [x] 5.3 Test zig build release fails when not on main branch
- [x] 5.4 Test zig build release fails when local/remote out of sync
- [x] 5.5 Test zig build release fails when version already released
- [x] 5.6 Test successful release creates draft with all artifacts attached
