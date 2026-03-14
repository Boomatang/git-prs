## 1. Add Width Calculation

- [x] 1.1 Add `calcMaxIdentifierWidth` function that iterates through PRs and returns the maximum identifier length
- [x] 1.2 Simplify `formatPRIdentifier` to remove truncation logic - just format and return full identifier

## 2. Update Row Formatters

- [x] 2.1 Add `identifier_width` parameter to `formatMineRow` function signature
- [x] 2.2 Update `formatMineRow` to use dynamic width for identifier column padding
- [x] 2.3 Add `identifier_width` parameter to `formatTeamRow` function signature
- [x] 2.4 Update `formatTeamRow` to use dynamic width for identifier column padding

## 3. Update Output Functions

- [x] 3.1 Update `formatMineOutput` to calculate max identifier width before rendering
- [x] 3.2 Update `formatMineOutput` header to use dynamic identifier column width
- [x] 3.3 Update `formatTeamOutput` to calculate max identifier width before rendering
- [x] 3.4 Update `formatTeamOutput` header to use dynamic identifier column width

## 4. Update Buffer Sizes

- [x] 4.1 Increase identifier buffer size from 25 to 256 bytes in row formatters

## 5. Update Tests

- [x] 5.1 Update `formatPRIdentifier` tests to verify no truncation occurs
- [x] 5.2 Add test for `calcMaxIdentifierWidth` function
- [x] 5.3 Update output tests to verify long identifiers are not truncated
