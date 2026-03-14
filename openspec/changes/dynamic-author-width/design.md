## Context

The team view currently displays the AUTHOR column with a hardcoded width of 8 characters:
- `formatTeamRow` truncates author to 8 chars: `truncate(pr.author, 8, ...)`
- `formatTeamOutput` calculates fixed columns assuming `AUTHOR(8)`
- Header prints with fixed padding: `{s: <8}`

This is inconsistent with the ORG/REPO#NUM column which uses `calcMaxIdentifierWidth()` to size dynamically based on content.

## Goals / Non-Goals

**Goals:**
- AUTHOR column width adapts to actual content in result set
- AUTHOR truncates first when terminal width is constrained (before TITLE)
- Minimum author width of 6 when truncation is required
- Follow existing patterns (`calcMaxIdentifierWidth`, `calcMaxTitleWidth`)

**Non-Goals:**
- Maximum cap on author width (can add later if needed)
- Changes to mine view (no AUTHOR column there)
- Changes to JSON output format

## Decisions

### Decision 1: Add `calcMaxAuthorWidth()` function

Follow the existing pattern:

```zig
fn calcMaxAuthorWidth(prs: []const PullRequest) usize {
    var max_width: usize = 6; // minimum "AUTHOR" header width
    for (prs) |pr| {
        if (pr.author.len > max_width) {
            max_width = pr.author.len;
        }
    }
    return max_width;
}
```

**Rationale**: Consistent with `calcMaxIdentifierWidth` and `calcMaxTitleWidth` patterns already in codebase.

### Decision 2: Author truncates before title

When terminal width is constrained, allocate space in this priority:
1. Fixed columns (AGE, 👤, LAST) - always get their fixed widths
2. ORG/REPO#NUM - always gets full width (already dynamic)
3. TITLE - gets remaining space (minimum 20)
4. AUTHOR - gets what's left after above, shrinks to MIN_AUTHOR_WIDTH (6) first

Algorithm:
```
required_fixed = identifier_width + 21 + MIN_TITLE_WIDTH  // 21 = spacing + AGE + 👤 + LAST
available_for_author = terminal_width - required_fixed

if available_for_author >= max_author_len:
    author_width = max_author_len
else if available_for_author >= MIN_AUTHOR_WIDTH:
    author_width = available_for_author
else:
    author_width = MIN_AUTHOR_WIDTH
    // title will also need to shrink
```

**Alternatives considered**:
- Equal priority with title: Rejected because author is less critical for identifying a PR than its title
- No minimum: Rejected because very short truncation (e.g., 3 chars) loses recognition value

### Decision 3: Update `formatTeamRow` signature

Add `author_width` parameter:

```zig
fn formatTeamRow(
    writer: anytype,
    pr: PullRequest,
    current_time: i64,
    title_width: usize,
    identifier_width: usize,
    author_width: usize,  // NEW
    url_inline: bool,
) !void
```

**Rationale**: Follows the existing pattern where column widths are calculated once in `formatTeamOutput` and passed to row formatter.

### Decision 4: Add MIN_AUTHOR_WIDTH constant

```zig
const MIN_AUTHOR_WIDTH: usize = 6;
```

**Rationale**: Matches the minimum established in user discussion. 6 characters allows most first names or recognizable username prefixes.

## Risks / Trade-offs

**[Risk]** Very long usernames dominate the layout → Mitigation: Accept for now; can add MAX_AUTHOR_WIDTH cap later if it becomes a problem in practice.

**[Trade-off]** More complex width calculation → Acceptable because it follows established patterns and the complexity is isolated to `formatTeamOutput`.

**[Trade-off]** Author column width varies between result sets → Acceptable; this is consistent with how identifier column already behaves.
