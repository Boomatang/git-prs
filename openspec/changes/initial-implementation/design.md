## Context

This is the initial implementation of `git-prs`, a CLI tool for reviewing open pull requests. The codebase currently contains only Zig boilerplate from `zig init`. The detailed technical specification exists at `docs/superpowers/specs/2026-03-13-git-prs-design.md` and should be treated as the source of truth for implementation details.

Key constraints:
- Zig 0.15.2 (no external dependencies beyond stdlib)
- Must integrate with `gh` CLI for authentication
- Target users are developers familiar with terminal tools

## Goals / Non-Goals

**Goals:**
- Implement `git-prs mine` and `git-prs team` commands
- Parse JSON config from XDG config directory
- Fetch PR data via GitHub GraphQL API
- Display compact table output to stdout

**Non-Goals:**
- Watch/daemon mode (explicitly never)
- CI status or review approval tracking
- Caching or offline mode
- Interactive TUI

## Decisions

### 1. Module Structure

**Decision:** Organize code into focused modules matching the architectural components.

```
src/
├── main.zig          # Entry point, CLI dispatch
├── cli.zig           # Argument parsing
├── config.zig        # Config loading and validation
├── github.zig        # GraphQL client
├── formatter.zig     # Table output
└── time.zig          # Duration formatting utilities
```

**Rationale:** Each module has a single responsibility and clear interfaces (defined in the spec). This enables independent testing and keeps files focused.

**Alternatives considered:**
- Single file: Rejected — would grow unwieldy and harder to test
- More granular split: Rejected — over-engineering for initial scope

### 2. Authentication Approach

**Decision:** Shell out to `gh auth token` rather than parsing gh's config files.

**Rationale:**
- `gh auth token` is a stable public interface
- Avoids coupling to gh's internal YAML config format
- Handles edge cases (keychain integration, token refresh) automatically

**Alternatives considered:**
- Parse `~/.config/gh/hosts.yml`: Rejected — internal format, YAML parsing needed
- Own token management: Rejected — duplicates gh's functionality

### 3. HTTP Client

**Decision:** Use `std.http.Client` from Zig standard library.

**Rationale:**
- Zero external dependencies
- Sufficient for GitHub API calls
- Well-tested as part of Zig stdlib

**Alternatives considered:**
- libcurl binding: Rejected — adds complexity and dependency
- Raw sockets: Rejected — reinventing the wheel

### 4. Error Output

**Decision:** Errors and warnings go to stderr; only table output goes to stdout.

**Rationale:** Standard Unix convention. Allows piping output while still seeing errors.

## Risks / Trade-offs

**[100 comment limit]** → PRs with >100 comments may show inaccurate data. Acceptable because highly active PRs are clearly getting attention. Documented as known limitation.

**[gh CLI dependency]** → Users must have gh installed and authenticated. Acceptable because target users are developers who likely already use gh. Clear error message guides installation.

**[GraphQL complexity]** → GitHub's GraphQL API has a learning curve. Mitigated by having the exact query documented in the spec.

**[Network latency]** → Multiple orgs means multiple API calls. Could be slow. Future optimization could parallelize requests, but initial implementation uses sequential calls for simplicity.

**[No caching]** → Every run fetches fresh data. Acceptable for weekly Monday-morning use case. Could add caching later if needed.
