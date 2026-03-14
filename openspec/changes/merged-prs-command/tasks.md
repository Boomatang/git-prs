## 1. CLI Argument Parsing

- [ ] 1.1 Add `MergedArgs` struct to `cli.zig` with fields: `days`, `since`, `until`, `org_filter`, `json`
- [ ] 1.2 Add `merged` variant to `Command` union
- [ ] 1.3 Implement `parseMergedArgs` function with flag parsing
- [ ] 1.4 Add validation to reject `--days` combined with `--since` or `--until`
- [ ] 1.5 Update `printUsage` to include merged command documentation

## 2. Date Computation

- [ ] 2.1 Add function to get current date as YYYY-MM-DD string
- [ ] 2.2 Add function to compute date N days ago from today
- [ ] 2.3 Integrate date computation into merged args processing (convert `--days` to `since` date)

## 3. GitHub API Integration

- [ ] 3.1 Add `fetchMergedPRs` function in `github.zig` using `is:merged` query
- [ ] 3.2 Use `merged:>=DATE` syntax for date filtering (not `created:>=DATE`)
- [ ] 3.3 Support optional `until` date with `merged:<=DATE` syntax

## 4. Output Formatting

- [ ] 4.1 Add `formatMergedUrlOutput` function in `formatter.zig` for plain URL output
- [ ] 4.2 Output one URL per line with no additional formatting
- [ ] 4.3 Display "No PRs merged in the last N days" message when no results
- [ ] 4.4 Support `--json` flag using existing `formatJsonOutput` function

## 5. Main Integration

- [ ] 5.1 Add merged command handler in `main.zig`
- [ ] 5.2 Wire up argument parsing, API call, and output formatting
- [ ] 5.3 Handle error cases (invalid flags, API errors)

## 6. Testing

- [ ] 6.1 Add CLI parsing tests for merged command flags
- [ ] 6.2 Add test for `--days` and `--since` mutual exclusion error
- [ ] 6.3 Add test for date computation functions
- [ ] 6.4 Add test for URL-only output formatting
- [ ] 6.5 Add test for empty result message
- [ ] 6.6 Run full test suite and verify all tests pass
