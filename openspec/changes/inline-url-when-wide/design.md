## Context

Currently, PR output always displays the URL on a second line with 4-space indentation:

```
k8s/kube#1234  Fix node scheduling bug           15m    4      2h
    https://github.com/k8s/kube/pull/1234
```

Terminal width is already detected via ioctl (with fallbacks to `COLUMNS` and default 80). The title column width is dynamically calculated based on available terminal width.

### Current Width Calculation

The existing code calculates title width as:
```
fixed_width = 21 + identifier_width  (for mine view)
fixed_width = 31 + identifier_width  (for team view)
title_width = terminal_width - fixed_width  (minimum 20)
```

The title expands to fill all remaining terminal space. This means the first line of output already fills the terminal width exactly.

## Goals / Non-Goals

**Goals:**
- Display URL inline when terminal is wide enough to fit all content on one line
- Preserve current two-line format when terminal is too narrow
- Maintain readability in both modes

**Non-Goals:**
- Adding a flag to force one mode or the other
- Changing JSON output format
- Truncating URLs to fit

## Decisions

### 1. Width Threshold Calculation

**Decision**: For each row, calculate whether displaying the URL inline would leave at least 20 characters for the title. If yes, display inline with a reduced title width; otherwise, use current two-line format with full title width.

The inline eligibility check:
```
url_space_needed = url.len + 2  (2-space separator)
available_for_title = terminal_width - fixed_columns - url_space_needed
inline_eligible = available_for_title >= MIN_TITLE_WIDTH (20)
```

When inline:
- Title width is reduced: `title_width = terminal_width - fixed_columns - url_space_needed`
- Title may be more aggressively truncated to make room for URL

When two-line (not inline eligible):
- Title width uses current calculation: `title_width = terminal_width - fixed_columns`
- URL appears on second line with 4-space indent (existing behavior)

**Rationale**: This approach prioritizes URL visibility when there's room, while ensuring titles remain readable (minimum 20 chars). The per-row calculation handles varying URL lengths gracefully.

**Alternative considered**: Always inline with URL truncation. Rejected because truncated URLs are not clickable/copyable and lose utility.

**Alternative considered**: Calculate once for all rows using longest URL. Rejected because it would force all rows to two-line format if any single URL is long, even when most URLs would fit inline.

### 2. Inline Format Layout

**Decision**: Append URL at end of row after existing columns, separated by 2 spaces.

```
k8s/kube#1234  Fix node scheduling bug           15m    4      2h  https://github.com/k8s/kube/pull/1234
```

**Rationale**: Follows existing column spacing conventions. URL is naturally at the end where it doesn't disrupt visual scanning of the core PR metadata.

### 3. Width Calculation Approach

**Decision**: Calculate inline eligibility before formatting each row, rather than pre-calculating for all rows.

Fixed column widths (excluding title):
- Mine view: `identifier_width + 2 + 5(AGE) + 2 + 3(👤) + 2 + 5(LAST) = identifier_width + 19`
- Team view: `8(AUTHOR) + 2 + identifier_width + 2 + 5(AGE) + 2 + 3(👤) + 2 + 5(LAST) = identifier_width + 29`

Note: The 👤 emoji is 1 character but displays as approximately 2 columns in most terminals. The current code treats it as 3 columns for spacing purposes.

Inline eligibility calculation:
```
fixed_columns = identifier_width + 19  (mine) or identifier_width + 29 (team)
url_space = url.len + 2  (URL + 2-space separator)
available_for_title = terminal_width - fixed_columns - url_space

if available_for_title >= 20:
    use inline format with title_width = available_for_title
else:
    use two-line format with title_width = terminal_width - fixed_columns
```

**Rationale**: Per-row calculation allows flexibility since URL lengths vary based on org/repo names. Simple and no additional data structures needed.

### 4. Minimum Title Width Constant

**Decision**: Use 20 characters as the minimum title width for inline display eligibility.

**Rationale**: 20 characters allows most PR titles to remain recognizable even when truncated. Shorter titles would be too cryptic ("Fix node sched..." vs "Fix..."). This matches the existing minimum title width fallback in the codebase.

## Risks / Trade-offs

**Mixed output format**: If terminal width is borderline, some rows may be inline and others two-line within the same output, creating visual inconsistency → Accept this trade-off; consistency matters less than fitting content optimally. Users with borderline widths can resize.

**URL column not aligned**: When inline, URLs won't form a neat column since they follow variable-width content → Acceptable since URLs are terminal content meant for clicking, not visual scanning.

**Title truncation varies per row**: When some rows are inline and others are two-line, titles will have different widths (inline titles are shorter to make room for URL) → Accept this; the alternative (uniform shortest title) would waste space on two-line rows.

## Edge Cases

### Very narrow terminal (< 80 columns)
When terminal width is less than `fixed_columns + MIN_TITLE_WIDTH`, all rows use two-line format. The existing minimum title width of 20 is preserved.

### Extremely long URL
If a URL is so long that even with minimum title width the row wouldn't fit, use two-line format. The URL on its own line may extend beyond terminal width (wrapping in terminal), which is acceptable since the URL remains complete and clickable.

### Very long identifier
Long org/repo names increase `identifier_width`, reducing space available for title and URL. The calculation handles this automatically since `identifier_width` is part of `fixed_columns`.

### Empty PR list
No change needed - existing "No open PRs found" behavior is unaffected.

### Single PR vs multiple PRs
Calculation is per-row, so behavior is consistent regardless of PR count.
