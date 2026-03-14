## 1. Data Model

- [ ] 1.1 Add `is_draft: bool` field to `PullRequest` struct in `github.zig`
- [ ] 1.2 Update `PullRequest.deinit` if needed (bool needs no cleanup)

## 2. GraphQL Query and Parsing

- [ ] 2.1 Add `isDraft` field to GraphQL query in `fetchPRsWithGh`
- [ ] 2.2 Parse `isDraft` in `parsePullRequestFromGraphQL` and set `is_draft` field

## 3. TTY Detection

- [ ] 3.1 Add `isStdoutTty()` function in `formatter.zig` using `isatty` check
- [ ] 3.2 Add ANSI code constants for dim+italic (`\x1b[2;3m`) and reset (`\x1b[0m`)

## 4. Row Formatting

- [ ] 4.1 Update `formatMineRow` to accept `is_tty` parameter and wrap draft rows with ANSI codes
- [ ] 4.2 Update `formatTeamRow` to accept `is_tty` parameter and wrap draft rows with ANSI codes
- [ ] 4.3 Update `formatMineOutput` to detect TTY and pass to row formatter
- [ ] 4.4 Update `formatTeamOutput` to detect TTY and pass to row formatter

## 5. JSON Output

- [ ] 5.1 Add `is_draft` field to `formatPrAsJson` function

## 6. Testing

- [ ] 6.1 Add test for `isStdoutTty` function behavior
- [ ] 6.2 Add test for draft row formatting with ANSI codes when TTY
- [ ] 6.3 Add test for draft row formatting without ANSI codes when not TTY
- [ ] 6.4 Add test for `is_draft` in JSON output
- [ ] 6.5 Run full test suite and verify all tests pass
