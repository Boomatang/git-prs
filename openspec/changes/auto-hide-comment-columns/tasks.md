## 1. Detection Logic

- [ ] 1.1 Add `hasAnyComments` function that iterates PRs and returns true if any has `unique_commenters > 0`
- [ ] 1.2 Add test for `hasAnyComments` with mix of commented and uncommented PRs
- [ ] 1.3 Add test for `hasAnyComments` with all zero commenters
- [ ] 1.4 Add test for `hasAnyComments` with empty PR list

## 2. Row Formatting Updates

- [ ] 2.1 Add `show_comments: bool` parameter to `formatMineRow` function signature
- [ ] 2.2 Conditionally print 👤 and LAST columns in `formatMineRow` based on `show_comments`
- [ ] 2.3 Add `show_comments: bool` parameter to `formatTeamRow` function signature
- [ ] 2.4 Conditionally print 👤 and LAST columns in `formatTeamRow` based on `show_comments`
- [ ] 2.5 Update existing `formatMineRow` tests to pass `show_comments` parameter
- [ ] 2.6 Update existing `formatTeamRow` tests to pass `show_comments` parameter
- [ ] 2.7 Add test for `formatMineRow` with `show_comments = false`
- [ ] 2.8 Add test for `formatTeamRow` with `show_comments = false`

## 3. Output Function Updates

- [ ] 3.1 Call `hasAnyComments` at start of `formatMineOutput` and store result
- [ ] 3.2 Adjust `fixed_columns` calculation in `formatMineOutput` when comments hidden (reduce by 12)
- [ ] 3.3 Conditionally print header columns in `formatMineOutput` based on comment visibility
- [ ] 3.4 Pass `show_comments` to `formatMineRow` calls in `formatMineOutput`
- [ ] 3.5 Call `hasAnyComments` at start of `formatTeamOutput` and store result
- [ ] 3.6 Adjust `fixed_columns` calculation in `formatTeamOutput` when comments hidden (reduce by 12)
- [ ] 3.7 Conditionally print header columns in `formatTeamOutput` based on comment visibility
- [ ] 3.8 Pass `show_comments` to `formatTeamRow` calls in `formatTeamOutput`

## 4. Integration Tests

- [ ] 4.1 Add test for `formatMineOutput` with all PRs having zero commenters (verify no 👤/LAST in output)
- [ ] 4.2 Add test for `formatTeamOutput` with all PRs having zero commenters (verify no 👤/LAST in output)
- [ ] 4.3 Add test for `formatMineOutput` with at least one PR having comments (verify 👤/LAST present)
- [ ] 4.4 Add test for `formatTeamOutput` with at least one PR having comments (verify 👤/LAST present)
- [ ] 4.5 Verify JSON output includes `unique_commenters` and `last_comment_at` regardless of values

## 5. Build and Verify

- [ ] 5.1 Run `zig build test` and verify all tests pass
- [ ] 5.2 Run `zig build` and verify successful compilation
- [ ] 5.3 Manual test: run `git-prs mine` with PRs having no comments and verify clean output
