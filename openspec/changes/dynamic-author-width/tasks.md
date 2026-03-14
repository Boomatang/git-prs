## 1. Core Implementation

- [ ] 1.1 Add `MIN_AUTHOR_WIDTH` constant (value: 6)
- [ ] 1.2 Add `calcMaxAuthorWidth` function following existing pattern
- [ ] 1.3 Update `formatTeamRow` signature to accept `author_width` parameter
- [ ] 1.4 Update `formatTeamRow` to use dynamic author width instead of hardcoded 8
- [ ] 1.5 Update `formatTeamOutput` to calculate author width using `calcMaxAuthorWidth`
- [ ] 1.6 Update `formatTeamOutput` fixed columns calculation to use dynamic author width
- [ ] 1.7 Update `formatTeamOutput` header to use dynamic author column padding

## 2. Truncation Priority

- [ ] 2.1 Implement author-first truncation logic in `formatTeamOutput`
- [ ] 2.2 Ensure TITLE gets remaining space after author truncation
- [ ] 2.3 Verify MIN_AUTHOR_WIDTH is respected when truncating

## 3. Tests

- [ ] 3.1 Add test for `calcMaxAuthorWidth` returning max author length
- [ ] 3.2 Add test for `calcMaxAuthorWidth` minimum width (6 for header)
- [ ] 3.3 Add test for full author display when terminal is wide
- [ ] 3.4 Add test for author truncation before title truncation
- [ ] 3.5 Add test for minimum author width preserved during truncation
- [ ] 3.6 Update existing `formatTeamRow` tests to include author_width parameter

## 4. Verification

- [ ] 4.1 Run full test suite
- [ ] 4.2 Manual test with `./zig-out/bin/git_prs team` on wide terminal
- [ ] 4.3 Manual test with narrow terminal to verify truncation priority
