## Context

The `formatter.zig` file contains two sorting functions:
- `sortByAge`: Used by `mine` command, sorts PRs by `created_at` timestamp
- `sortByAuthorThenAge`: Used by `team` command, sorts by author then by `created_at` within author groups

Both currently use `a.created_at < b.created_at` which produces ascending order (oldest first).

## Goals / Non-Goals

**Goals:**
- Reverse sort order so newest PRs appear first
- Maintain consistent behavior across both `mine` and `team` commands

**Non-Goals:**
- Adding sort order options or flags (just change the default)
- Changing author sort order in team view (keep alphabetical)

## Decisions

### Reverse comparison operator

**Decision**: Change `<` to `>` in timestamp comparisons.

**Rationale**: Simplest change with no side effects. Zig's `std.mem.sort` uses the comparison function to determine order - returning `true` when `a > b` produces descending order.

**Locations**:
- `sortByAge`: `return a.created_at > b.created_at;`
- `sortByAuthorThenAge`: `return a.created_at > b.created_at;` (within author groups)

## Risks / Trade-offs

**[Risk]** Tests will fail until updated
→ Update test expectations in same commit

**[Risk]** Design spec now contradicts code
→ Note: Design spec should be updated separately if needed
