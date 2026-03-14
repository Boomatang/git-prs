## 1. CLI Argument Parsing

- [x] 1.1 Add `MergedArgs` struct to `cli.zig` with fields: `days`, `since`, `until`, `org_filter`, `json`
- [x] 1.2 Add `merged` variant to `Command` union
- [x] 1.3 Implement `parseMergedArgs` function with flag parsing
- [x] 1.4 Add validation to reject `--days` combined with `--since` or `--until`
- [x] 1.5 Update `printUsage` to include merged command documentation

## 2. Date Computation

- [x] 2.1 Add function to get current date as YYYY-MM-DD string
- [x] 2.2 Add function to compute date N days ago from today
- [x] 2.3 Integrate date computation into merged args processing (convert `--days` to `since` date)

## 3. GitHub API Integration

- [x] 3.1 Add `fetchMergedPRs` function in `github.zig` using `is:merged` query
- [x] 3.2 Use `merged:>=DATE` syntax for date filtering (not `created:>=DATE`)
- [x] 3.3 Support optional `until` date with `merged:<=DATE` syntax

## 4. Output Formatting

- [x] 4.1 Add `formatMergedUrlOutput` function in `formatter.zig` for plain URL output
- [x] 4.2 Output one URL per line with no additional formatting
- [x] 4.3 Display "No PRs merged in the last N days" message when no results
- [x] 4.4 Support `--json` flag using existing `formatJsonOutput` function

## 5. Main Integration

- [x] 5.1 Add merged command handler in `main.zig`
- [x] 5.2 Wire up argument parsing, API call, and output formatting
- [x] 5.3 Handle error cases (invalid flags, API errors)

## 6. Testing

- [x] 6.1 Add CLI parsing tests for merged command flags
- [x] 6.2 Add test for `--days` and `--since` mutual exclusion error
- [x] 6.3 Add test for date computation functions
- [x] 6.4 Add test for URL-only output formatting
- [x] 6.5 Add test for empty result message
- [x] 6.6 Run full test suite and verify all tests pass
