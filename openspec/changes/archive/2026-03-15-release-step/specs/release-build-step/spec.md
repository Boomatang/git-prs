## ADDED Requirements

### Requirement: Release step available
The build system SHALL provide a `release` step invokable via `zig build release`.

#### Scenario: Release step exists
- **WHEN** user runs `zig build --help`
- **THEN** output includes "release" step with description "Create a GitHub release"

### Requirement: Pre-flight check for gh CLI
The release step SHALL verify that the `gh` CLI is available before proceeding.

#### Scenario: gh CLI not found
- **WHEN** user runs `zig build release` and `gh` is not in PATH
- **THEN** build fails with error message "Error: gh CLI not found. Install from https://cli.github.com/"

### Requirement: Pre-flight check for clean working directory
The release step SHALL verify that the working directory has no uncommitted changes.

#### Scenario: Working directory has changes
- **WHEN** user runs `zig build release` with uncommitted changes
- **THEN** build fails with error message "Error: Working directory not clean. Commit or stash changes first."

### Requirement: Pre-flight check for main branch
The release step SHALL verify that HEAD is on the main branch.

#### Scenario: Not on main branch
- **WHEN** user runs `zig build release` while on branch "feature-x"
- **THEN** build fails with error message "Error: Must be on main branch to release."

### Requirement: Pre-flight check for remote sync
The release step SHALL verify that local main matches origin/main.

#### Scenario: Local ahead of remote
- **WHEN** user runs `zig build release` with unpushed commits
- **THEN** build fails with error message "Error: Local main is not in sync with origin/main. Push or pull first."

#### Scenario: Local behind remote
- **WHEN** user runs `zig build release` with remote having newer commits
- **THEN** build fails with error message "Error: Local main is not in sync with origin/main. Push or pull first."

### Requirement: Pre-flight check for version not released
The release step SHALL verify that the version from build.zig.zon has not been released.

#### Scenario: Version tag exists locally
- **WHEN** user runs `zig build release` and local git tag v0.1.0 exists
- **THEN** build fails with error message "Error: Tag v0.1.0 already exists."

#### Scenario: Version release exists on GitHub
- **WHEN** user runs `zig build release` and GitHub release v0.1.0 exists
- **THEN** build fails with error message "Error: Release v0.1.0 already exists on GitHub."

### Requirement: Clean artifacts directory
The release step SHALL remove existing artifacts before building.

#### Scenario: Stale artifacts exist
- **WHEN** user runs `zig build release` with previous artifacts in zig-out/artifacts/
- **THEN** the directory is cleaned before new artifacts are built

### Requirement: Build release artifacts
The release step SHALL build cross-compiled artifacts for all supported targets.

#### Scenario: Artifacts built successfully
- **WHEN** all pre-flight checks pass
- **THEN** release step builds .tar.gz and .sha256 files for linux-x86_64, linux-aarch64, macos-x86_64, macos-aarch64

### Requirement: Create draft GitHub release
The release step SHALL create a draft release on GitHub with all artifacts attached.

#### Scenario: Draft release created
- **WHEN** artifacts are built successfully
- **THEN** `gh release create` is invoked with:
  - Tag: v{version} from build.zig.zon
  - Title: "git-prs v{version}"
  - --draft flag
  - --generate-notes flag
  - All .tar.gz and .sha256 files from zig-out/artifacts/

### Requirement: Output release URL
The release step SHALL display the URL to the created draft release.

#### Scenario: Success message shown
- **WHEN** draft release is created successfully
- **THEN** output includes the GitHub release URL and instruction to publish when ready
