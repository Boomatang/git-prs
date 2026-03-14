## Context

The formatter currently calculates title width as: `terminal_width - fixed_columns` (or the space available after accounting for inline URL). This fills all available horizontal space regardless of actual PR title lengths. When titles are short (e.g., "Feature create" at 14 chars), the column is padded with excessive whitespace.

Current flow in `formatMineOutput` and `formatTeamOutput`:
1. Calculate `fixed_columns` (identifier + age + commenters + last)
2. Calculate `title_width = terminal_width - fixed_columns`
3. Pad all titles to `title_width`

## Goals / Non-Goals

**Goals:**
- Title column width adapts to actual content, reducing unnecessary whitespace
- Maintain minimum width (20 chars) for readability
- Consistent column width across all rows (based on longest title in result set)

**Non-Goals:**
- Per-row dynamic title widths (would misalign columns)
- Changes to URL display logic (inline vs two-line)
- Changes to other column calculations

## Decisions

### Decision 1: Add `calcMaxTitleWidth` function

Add a new function similar to existing `calcMaxIdentifierWidth`:

```zig
fn calcMaxTitleWidth(prs: []const PullRequest) usize {
    var max_width: usize = 5; // minimum "TITLE" header width
    for (prs) |pr| {
        if (pr.title.len > max_width) {
            max_width = pr.title.len;
        }
    }
    return max_width;
}
```

**Rationale**: Follows existing pattern for `calcMaxIdentifierWidth`. Single pass through PRs is efficient.

### Decision 2: Constrain title width to actual content

Modify title width calculation:

```zig
const max_title_len = calcMaxTitleWidth(sorted_prs);
const available_width = terminal_width - fixed_columns;
const title_width = @min(max_title_len, available_width);
```

Apply minimum constraint:
```zig
const title_width = @max(MIN_TITLE_WIDTH, @min(max_title_len, available_width));
```

**Rationale**: Title column is sized to content unless content exceeds available space, in which case truncation applies as before.

### Decision 3: Add small margin to title width

Add 2 character margin for visual breathing room:

```zig
const title_width = @max(MIN_TITLE_WIDTH, @min(max_title_len + 2, available_width));
```

**Rationale**: Titles that exactly match column width look cramped. Small margin improves readability without significant space cost.

## Risks / Trade-offs

**[Slight output change]** → Users accustomed to full-width title column may notice the change. This is intentional and improves readability.

**[Extra pass through PR list]** → Minor performance impact from calling `calcMaxTitleWidth`. Negligible for typical PR counts (<100).
