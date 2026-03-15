## 1. Core Implementation

- [x] 1.1 Add constant `MIN_TITLE_WIDTH = 20` for minimum title width threshold
- [x] 1.2 Add helper function `urlFitsInline(terminal_width: u32, fixed_columns: usize, url_len: usize) -> ?usize` that returns the available title width if inline is eligible, or null if not
- [x] 1.3 Update `formatMineRow` signature to accept `url_inline: bool` and `title_width: usize` parameters
- [x] 1.4 Update `formatMineRow` to conditionally display URL inline (with 2-space separator) or on separate line (with 4-space indent) based on `url_inline` flag
- [x] 1.5 Update `formatTeamRow` signature to accept `url_inline: bool` and `title_width: usize` parameters
- [x] 1.6 Update `formatTeamRow` to conditionally display URL inline or on separate line based on `url_inline` flag
- [x] 1.7 Update `formatMineOutput` to calculate per-row inline eligibility and title_width, passing to `formatMineRow`
- [x] 1.8 Update `formatTeamOutput` to calculate per-row inline eligibility and title_width, passing to `formatTeamRow`

## 2. Testing

### Inline eligibility helper tests
- [x] 2.1 Test `urlFitsInline` returns title width when URL fits (e.g., terminal=150, fixed=35, url=45 → returns 68)
- [x] 2.2 Test `urlFitsInline` returns null when URL doesn't fit (e.g., terminal=80, fixed=35, url=45 → returns null, since 80-35-45-2=−2 < 20)
- [x] 2.3 Test `urlFitsInline` returns exactly 20 at threshold boundary

### Mine view format tests
- [x] 2.4 Test mine view inline URL display with wide terminal (150 columns): verify URL appears after LAST column with 2-space separator
- [x] 2.5 Test mine view two-line URL display with narrow terminal (80 columns): verify URL on second line with 4-space indent
- [x] 2.6 Test mine view with borderline width: verify correct format decision at exact threshold

### Team view format tests
- [x] 2.7 Test team view inline URL display with wide terminal (160 columns): verify URL appears after LAST column with 2-space separator
- [x] 2.8 Test team view two-line URL display with narrow terminal (80 columns): verify URL on second line with 4-space indent
- [x] 2.9 Test team view with borderline width: verify correct format decision at exact threshold

### Edge case tests
- [x] 2.10 Test mixed format output: multiple PRs with varying URL lengths produce mixed inline/two-line output
- [x] 2.11 Test URLs are never truncated in either format
- [x] 2.12 Test very long URL (>100 chars) forces two-line format
- [x] 2.13 Test very long identifier reduces space, affecting inline eligibility
- [x] 2.14 Test minimum title width (20) is preserved in all cases
