## Context

The application displays PR lists in table format via `formatMineOutput` and `formatTeamOutput` in `formatter.zig`. The `PullRequest` struct in `github.zig` holds PR data fetched via GraphQL. Currently, draft status is not captured or displayed.

GitHub's GraphQL API provides an `isDraft` boolean field on PullRequest objects that can be queried directly.

The display uses fixed-width columns and adapts to terminal width. ANSI escape codes are not currently used anywhere in the codebase.

## Goals / Non-Goals

**Goals:**
- Visually differentiate draft PRs from ready PRs without adding columns
- Fetch draft status from GitHub API efficiently (single query, no extra requests)
- Preserve clean output when piped to other tools
- Include draft status in JSON output

**Non-Goals:**
- `--color=always|never|auto` flag (future scope for broader color support)
- Filtering drafts in/out of results
- Other visual enhancements or colors

## Decisions

### 1. Use dim + italic ANSI styling for entire row

**Choice:** Apply `\x1b[2;3m` (dim + italic) to entire draft PR rows, reset with `\x1b[0m`

**Alternatives considered:**
- Dim only: Less differentiation, but more universally supported
- Italic only: Semantic "different" rather than "de-emphasized", inconsistent terminal support
- Title prefix `[draft]`: Consumes 8 chars of title space, adds visual noise
- Separate DRAFT column: Wastes space when no drafts present

**Rationale:** Dim + italic provides strong visual differentiation. The entire row treatment makes drafts "recede" visually, drawing attention to ready PRs. If a terminal doesn't support italic, dim alone still works.

### 2. TTY detection for conditional styling

**Choice:** Check `isatty(stdout)` before applying ANSI codes

**Alternatives considered:**
- Always emit codes: Breaks piped output, grep, etc.
- Never emit codes: Loses the visual benefit

**Rationale:** Standard CLI convention. Users piping to files or other tools get clean output. Interactive terminal users get styled output.

### 3. Add is_draft to existing GraphQL query

**Choice:** Add `isDraft` field to the existing search query alongside other PR fields

**Alternatives considered:**
- Separate API call: Wasteful, adds latency
- Use REST API: Would require different parsing, inconsistent with current approach

**Rationale:** GraphQL already fetches all PR data in one query. Adding one boolean field has negligible cost.

## Risks / Trade-offs

**[Risk] Terminal doesn't support dim/italic** → Falls back gracefully. Dim is widely supported; worst case, text appears normal.

**[Risk] ANSI codes in unexpected places** → TTY detection prevents this. Only stdout to terminals gets styling.

**[Trade-off] Entire row styling vs just title** → Chose entire row for stronger visual effect. May make identifiers slightly harder to read for drafts, but drafts are de-prioritized by design.
