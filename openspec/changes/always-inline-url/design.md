## Context

The current formatter has two display modes for PR URLs:
1. **Inline mode**: URL appears at the end of the row when terminal is wide enough (W - F - U - 2 >= 20)
2. **Two-line mode**: URL appears on a separate indented line when terminal is narrow

The decision is made per-row based on URL length, which can result in mixed formats within the same output. On narrow terminals, every PR takes two lines, doubling vertical space and breaking visual scanning patterns.

The formatter currently truncates columns in this priority: Author → Title. The identifier (ORG/REPO#NUM) is never truncated.

## Goals / Non-Goals

**Goals:**
- Always display URL inline on the same row as PR data
- Implement cascading truncation: Title → Author → Identifier (ORG → REPO)
- Allow columns to shrink more aggressively to accommodate the URL
- Maintain readable output even on narrow terminals

**Non-Goals:**
- Changing JSON output format
- Adding user-configurable truncation preferences
- Supporting terminals narrower than reasonable minimums

## Decisions

### Decision 1: Remove two-line URL display entirely

**Choice**: Delete the two-line code path and always use inline display.

**Rationale**: Simplifies the code (one display mode instead of two), provides consistent visual formatting, and matches user preference for scannable single-line output.

**Alternative considered**: Keep two-line as a fallback for extremely narrow terminals. Rejected because users indicated they'd rather have truncated columns and natural line wrapping than a separate URL line.

### Decision 2: Truncation priority chain

**Choice**: Title → Author → Identifier (ORG → REPO), URL never truncates.

**Rationale**:
- Title is most flexible (users can infer meaning from truncated titles)
- Author is next (username truncation is recognizable)
- Identifier truncates last (needed to identify the PR, but ORG is often predictable within a team context)
- URL must remain complete for click/copy functionality

**Alternative considered**: Truncate identifier before author. Rejected because the repo identifier is essential for distinguishing PRs across multiple repositories.

### Decision 3: Minimum column widths

**Choice**:
- Title: minimum 3 characters (just "...")
- Author: minimum 4 characters + "..." = 7 characters total
- ORG: minimum 4 characters + "..." = 7 characters total
- REPO: minimum 4 characters + "..." = 7 characters total
- Number: never truncated

**Rationale**: Lower minimums allow more aggressive truncation to accommodate URLs on narrow terminals. The 4-character minimum for names preserves some recognizability.

### Decision 4: Identifier truncation implementation

**Choice**: Modify `formatPRIdentifier()` to accept a max width and truncate ORG first, then REPO if needed.

**Rationale**: Centralizes identifier formatting logic. ORG truncates first because within a team context, the organization is often the same across all PRs.

Format progression:
```
very-long-organization/very-long-repository#12345  (full)
very.../very-long-repository#12345                 (ORG truncated)
very.../very...#12345                              (both truncated)
```

## Risks / Trade-offs

**[Risk] Very long URLs cause excessive line wrapping** → Acceptable; user indicated natural terminal wrapping is fine. URLs must remain complete for functionality.

**[Risk] Minimum column widths may be unreadable** → Mitigated by 4-char minimums preserving some recognizability. Users with very narrow terminals can widen them.

**[Trade-off] Removes user choice between formats** → Accepted; single consistent format is the explicit goal.

**[Trade-off] Identifier truncation adds complexity** → Acceptable; localized to one function and well-defined rules.
