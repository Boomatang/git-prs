## 1. Data Model

- [x] 1.1 Add `is_draft: bool` field to `PullRequest` struct in `github.zig`
- [x] 1.2 Update `PullRequest.deinit` if needed (bool needs no cleanup)

## 2. GraphQL Query and Parsing

- [x] 2.1 Add `isDraft` field to GraphQL query in `fetchPRsWithGh`
- [x] 2.2 Parse `isDraft` in `parsePullRequestFromGraphQL` and set `is_draft` field

## 3. TTY Detection

- [x] 3.1 Add `isStdoutTty()` function in `formatter.zig` using `isatty` check
- [x] 3.2 Add ANSI code constants for dim+italic (`\x1b[2;3m`) and reset (`\x1b[0m`)

## 4. Row Formatting

- [x] 4.1 Update `formatMineRow` to accept `is_tty` parameter and wrap draft rows with ANSI codes
- [x] 4.2 Update `formatTeamRow` to accept `is_tty` parameter and wrap draft rows with ANSI codes
- [x] 4.3 Update `formatMineOutput` to detect TTY and pass to row formatter
- [x] 4.4 Update `formatTeamOutput` to detect TTY and pass to row formatter

## 5. JSON Output

- [x] 5.1 Add `is_draft` field to `formatPrAsJson` function

## 6. Testing

- [x] 6.1 Add test for `isStdoutTty` function behavior
- [x] 6.2 Add test for draft row formatting with ANSI codes when TTY
- [x] 6.3 Add test for draft row formatting without ANSI codes when not TTY
- [x] 6.4 Add test for `is_draft` in JSON output
- [x] 6.5 Run full test suite and verify all tests pass
