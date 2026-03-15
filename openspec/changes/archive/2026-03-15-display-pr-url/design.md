## Context

The `formatter.zig` module currently renders each PR as a single row in a table. The `PullRequest` struct already contains a `url` field with the full GitHub PR URL (e.g., `https://github.com/k8s/kube/pull/1234`), but this data is not displayed.

Users want to quickly copy/click the URL to open PRs in their browser.

## Goals / Non-Goals

**Goals:**
- Display the full PR URL below each row
- Visually group the URL with its PR row using indentation
- Apply consistently to both mine and team views

**Non-Goals:**
- Making URLs clickable (terminal-dependent feature)
- Shortening or truncating URLs
- Optional URL display via flag

## Decisions

### 1. Display URL on second line

**Decision**: Add the URL as a separate line immediately following the PR data row.

**Rationale**:
- Adding a URL column would make rows too wide
- Footer/reference style adds cognitive overhead (matching numbers to URLs)
- Second line keeps related info together and is easy to copy

### 2. Indent with 4 spaces

**Decision**: Prefix the URL line with 4 spaces.

**Rationale**:
- Visually indicates the URL belongs to the row above
- Consistent indentation across all rows
- 4 spaces is sufficient without wasting horizontal space

### 3. Modify row formatters directly

**Decision**: Add the URL output directly in `formatMineRow` and `formatTeamRow` functions.

**Rationale**:
- Keeps all per-PR formatting logic in one place
- Simple implementation - just one additional print statement
- No need for new helper functions

## Risks / Trade-offs

**[Risk]** Output becomes longer (2 lines per PR instead of 1)
→ Acceptable; URLs provide significant value and vertical space is rarely constrained

**[Risk]** Copy/paste of table becomes messier
→ Minor concern; users typically copy individual URLs, not entire tables
