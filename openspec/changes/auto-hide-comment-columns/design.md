## Context

The formatter currently always displays the 👤 (unique commenters) and LAST (last comment time) columns in both mine and team table views. When no PRs have any comments, these columns show `0` and `-` for every row, adding visual clutter without providing value.

Current fixed column width calculations assume these columns are always present:
- Mine view: `identifier_width + 21` (includes 👤 and LAST spacing)
- Team view: `author_width + identifier_width + 23` (includes 👤 and LAST spacing)

## Goals / Non-Goals

**Goals:**
- Automatically hide comment columns when all PRs have zero commenters
- Maintain consistent output across mine and team views
- Preserve current behavior when any PR has comments
- Keep JSON output unchanged for programmatic consumers

**Non-Goals:**
- User-configurable column visibility (auto-detect only)
- Hiding other columns based on content
- Changes to merged command output

## Decisions

### Decision 1: Detection based on `unique_commenters` field only

Check if any PR has `unique_commenters > 0` rather than checking `last_comment_at`.

**Rationale**: The `unique_commenters` count is the primary indicator. If a PR has comments, `unique_commenters > 0`. The `last_comment_at` field could theoretically be null with comments in edge cases. Using a single field keeps logic simple.

**Alternative considered**: Check both fields - rejected as unnecessarily complex.

### Decision 2: Single boolean controlling both columns

Use one `show_comments` boolean to control visibility of both 👤 and LAST columns together.

**Rationale**: These columns are semantically linked - showing one without the other would be confusing. A single flag keeps the logic simple and ensures consistent behavior.

**Alternative considered**: Separate visibility per column - rejected as over-engineering.

### Decision 3: Detect once per output, not per row

Run `hasAnyComments()` once at the start of `formatMineOutput`/`formatTeamOutput`, then pass the result to row formatting functions.

**Rationale**: Detection is O(n) over PRs but only needs to run once. Passing a boolean to each row is cleaner than re-checking or using global state.

### Decision 4: Adjust fixed_columns calculation conditionally

When comments are hidden, reduce `fixed_columns` by 12 characters (2 spaces + 3 for 👤 + 2 spaces + 5 for LAST).

**Rationale**: This allows more space for the title column when comment columns are hidden, maximizing use of terminal width.

## Risks / Trade-offs

**Risk**: Output format changes based on data content.
→ Mitigation: This is intentional UX improvement. Scripts should use `--json` for stable output.

**Risk**: Users may not notice missing columns initially.
→ Mitigation: Columns reappear automatically when any PR has comments. The behavior is self-documenting.

**Trade-off**: Slightly more complex formatting logic.
→ Acceptable: The added complexity is localized to the formatter and well-tested.
