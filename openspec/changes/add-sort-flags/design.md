## Context

Currently, PR output sorting is hardcoded in `formatter.zig`:
- `mine` command: sorts by `created_at` descending (newest first) via `sortByAge`
- `team` command: sorts by author alphabetically, then by age descending via `sortByAuthorThenAge`

Users have no way to customize this order. The sorting logic is embedded in the format functions, making it inflexible.

The CLI already uses zig-clap for argument parsing, which supports repeated flags.

## Goals / Non-Goals

**Goals:**
- Allow users to specify custom sort order via `--sort` flags
- Support multi-level sorting (primary, secondary, etc.)
- Maintain backwards compatibility with existing default behavior
- Validate sort field applicability per command (e.g., `author` invalid for `mine`)

**Non-Goals:**
- Visual grouping with headers (sorted-together is sufficient for now)
- Persistent sort preferences (config file storage)
- Custom sort field aliases or shortcuts

## Decisions

### Decision 1: Flag syntax `--sort field[:direction]`

**Choice**: `--sort age:desc` with optional direction defaulting to `asc`

**Alternatives considered**:
- `--sort-by age --sort-dir desc`: Verbose, harder to pair multiple criteria
- `--sort=age,desc`: Non-standard delimiter, harder to parse
- `--sort age --desc`: Direction as separate flag, ambiguous with multiple sorts

**Rationale**: The colon syntax is compact, unambiguous, and common in CLI tools (e.g., `docker ps --format`). Defaulting to ascending matches user expectation that "sort" means low-to-high.

### Decision 2: Multiple flags applied left-to-right

**Choice**: First `--sort` is primary, subsequent ones break ties

**Rationale**: Matches user mental model of "sort by X, then by Y". Consistent with SQL ORDER BY semantics.

### Decision 3: Null handling for `last` field

**Choice**: Nulls sort as "smallest value" - first in ascending, last in descending

**Alternatives considered**:
- Always first: Inconsistent between directions
- Always last: Also inconsistent
- Configurable: Over-engineering for edge case

**Rationale**: Treating null as "no value" / smallest is intuitive. PRs with no comments naturally sort to the "low" end.

### Decision 4: Per-command field validation

**Choice**: Error if user specifies `--sort author` for `mine` command

**Alternatives considered**:
- Silently ignore: Confusing, user might not realize it's not working
- Warning but continue: Mixed signals

**Rationale**: Fast failure with clear error message helps users understand the tool's behavior.

### Decision 5: Data structure for sort criteria

**Choice**: New `SortCriteria` struct with `field: SortField` enum and `direction: SortDirection` enum. Commands store `[]SortCriteria` slice.

**Rationale**: Type-safe representation, easy to validate, simple to iterate during sorting.

## Risks / Trade-offs

**Risk**: Performance with many sort criteria
- **Mitigation**: PR lists are typically small (<100 items). Multi-criteria comparison is O(n log n * k) where k is criteria count. Acceptable for expected usage.

**Risk**: zig-clap repeated flag handling
- **Mitigation**: zig-clap supports repeated options via `.{ .multi = true }`. Need to verify exact API.

**Trade-off**: No visual grouping
- Sorting PRs together by repo/author achieves grouping effect without visual headers. May revisit if users request explicit headers.
