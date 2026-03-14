## Context

The inline URL display feature was added to show URLs on the same line as PR data when the terminal is wide enough. However, the header rendering was not updated to account for this:

1. Header row prints: `ORG/REPO#NUM  TITLE  AGE  👤  LAST` but data rows include URL after LAST
2. Separator line calculates `total_width` without URL column, stopping short of the actual row width

Current header code in `formatMineOutput` (line 263):
```zig
try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST\n", .{});
```

Current separator calculation (line 266):
```zig
const total_width = identifier_width + 2 + title_width + 2 + 5 + 4 + 3 + 4 + 5;
```

Neither accounts for the URL column when `use_inline` is true.

## Goals / Non-Goals

**Goals:**
- Add "URL" to header when inline mode is active
- Extend separator to full row width including URL column
- Maintain consistent spacing (2-space separator before URL, matching data rows)

**Non-Goals:**
- Changes to two-line URL display mode
- Changes to URL column width calculation

## Decisions

### Decision 1: Conditionally append URL header

When `use_inline` is true, append "  URL" after LAST in the header row:

```zig
if (use_inline) {
    try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST  URL\n", .{});
} else {
    try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST\n", .{});
}
```

**Rationale**: Simple conditional that matches the existing pattern for data row formatting.

### Decision 2: Include URL length in separator width

When `use_inline` is true, add `2 + max_url_len` to total_width:

```zig
const base_width = identifier_width + 2 + title_width + 2 + 5 + 4 + 3 + 4 + 5;
const total_width = if (use_inline) base_width + 2 + max_url_len else base_width;
```

**Rationale**: The 2 accounts for the separator spaces before URL, and `max_url_len` ensures the line extends to the longest URL.

## Risks / Trade-offs

**[Minimal visual change]** → Users may notice the extended separator and new header. This is intentional and improves table completeness.
