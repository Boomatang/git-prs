## 1. Remove Two-Line URL Display

- [ ] 1.1 Delete `urlFitsInline()` function from formatter.zig
- [ ] 1.2 Remove `use_inline` variable and conditional logic in `formatMineOutput()`
- [ ] 1.3 Remove `use_inline` variable and conditional logic in `formatTeamOutput()`
- [ ] 1.4 Remove two-line URL printing code from `formatMineRow()` (lines 176-179)
- [ ] 1.5 Remove two-line URL printing code from `formatTeamRow()` (lines 260-263)
- [ ] 1.6 Update header printing to always include "URL" column in both views

## 2. Implement Identifier Truncation

- [ ] 2.1 Create `truncateIdentifier()` function that accepts max width and returns truncated ORG/REPO#NUM
- [ ] 2.2 Implement ORG truncation first (min 4 chars + "...")
- [ ] 2.3 Implement REPO truncation second (min 4 chars + "...")
- [ ] 2.4 Ensure PR number is never truncated
- [ ] 2.5 Update `formatPRIdentifier()` to use new truncation logic when width constrained

## 3. Update Truncation Priority Chain

- [ ] 3.1 Update `formatMineOutput()` to calculate available space for flexible columns
- [ ] 3.2 Update `formatTeamOutput()` to calculate available space for flexible columns
- [ ] 3.3 Implement title truncation first (can shrink to minimum 3 chars)
- [ ] 3.4 Implement author truncation second (min 4 chars + "..." = 7 total)
- [ ] 3.5 Implement identifier truncation last (using new truncateIdentifier function)
- [ ] 3.6 Update MIN_TITLE_WIDTH constant from 20 to 3
- [ ] 3.7 Update MIN_AUTHOR_WIDTH constant from 6 to 4

## 4. Update Column Width Calculations

- [ ] 4.1 Modify `formatMineOutput()` to always allocate space for URL in row
- [ ] 4.2 Modify `formatTeamOutput()` to always allocate space for URL in row
- [ ] 4.3 Calculate flexible column widths after reserving space for URL and fixed columns
- [ ] 4.4 Distribute remaining space to flexible columns based on truncation priority

## 5. Update Tests

- [ ] 5.1 Remove tests for `urlFitsInline()` function
- [ ] 5.2 Remove tests for two-line URL display scenarios
- [ ] 5.3 Add tests for `truncateIdentifier()` with various width constraints
- [ ] 5.4 Add tests for ORG-only truncation
- [ ] 5.5 Add tests for ORG and REPO truncation
- [ ] 5.6 Update `formatMineOutput` tests to expect inline URL always
- [ ] 5.7 Update `formatTeamOutput` tests to expect inline URL always
- [ ] 5.8 Add tests for cascading truncation priority (title → author → identifier)
- [ ] 5.9 Verify all existing tests pass or are updated appropriately
