## Context

The current `formatter.zig` hardcodes the ORG/REPO#NUM column to 25 characters:
- `formatMineRow` and `formatTeamRow` use `var identifier_buffer: [25]u8`
- `formatPRIdentifier` truncates identifiers exceeding 25 characters with "..."
- Long org/repo names like `very-long-organization/very-long-repository#12345` get truncated to something like `very-long-org...#12345`

Users need to see full identifiers to know which PRs they're looking at.

## Goals / Non-Goals

**Goals:**
- Display full ORG/REPO#NUM identifiers without truncation
- Dynamically size the identifier column based on actual content
- Maintain readable output format

**Non-Goals:**
- Terminal width-constrained output (explicitly allowing rows to exceed terminal width)
- Horizontal scrolling or pagination
- Truncation fallback options

## Decisions

### 1. Pre-scan PRs for maximum identifier width

**Decision**: Calculate the maximum identifier width by iterating through all PRs before rendering any rows.

**Rationale**:
- Allows all rows to align with consistent column widths
- Single pass through PR list is negligible overhead (already sorted in memory)
- Alternative (render as we go, pad later) would require buffering all output

### 2. Remove truncation from identifier formatting

**Decision**: Simplify `formatPRIdentifier` to always return the full identifier without truncation.

**Rationale**:
- The truncation logic is no longer needed
- Simpler code is easier to maintain
- Buffer size becomes the only constraint (use 256 bytes to handle any realistic org/repo/number combination)

### 3. Pass identifier width to row formatters

**Decision**: Add `identifier_width` parameter to `formatMineRow` and `formatTeamRow`.

**Rationale**:
- Allows dynamic column alignment
- Keeps width calculation in the output functions where it belongs
- Clean separation between width calculation and row rendering

### 4. Allow output to exceed terminal width

**Decision**: Do not constrain total row width to terminal width.

**Rationale**:
- User explicitly requested full identifiers over width constraints
- Modern terminals handle wide output (horizontal scrolling, wrapping)
- Title column still gets flexible width based on terminal size for readability

## Risks / Trade-offs

**[Risk]** Wide output wraps awkwardly on narrow terminals
→ Acceptable trade-off per user requirement; full identifiers are more important than perfect formatting

**[Risk]** Very long org/repo names could make output hard to read
→ Unlikely in practice; GitHub org/repo names have reasonable limits
