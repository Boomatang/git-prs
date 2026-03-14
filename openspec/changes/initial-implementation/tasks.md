## 1. Project Structure Setup

- [x] 1.1 Create module files: cli.zig, config.zig, github.zig, formatter.zig, time.zig
- [x] 1.2 Update main.zig to import and wire together modules
- [x] 1.3 Update build.zig to include new source files in module

## 2. Time Formatting Utilities

- [x] 2.1 Implement duration formatting function (minutes, hours, days, weeks, months)
- [x] 2.2 Add tests for time formatting edge cases

## 3. CLI Parser

- [x] 3.1 Define Command union type with MineArgs and TeamArgs structs
- [x] 3.2 Implement argument parsing for `mine` command with --org and --limit flags
- [x] 3.3 Implement argument parsing for `team` command with --org and --member flags
- [x] 3.4 Implement --help flag and usage output
- [x] 3.5 Add error handling for invalid commands and flags
- [x] 3.6 Add tests for CLI parsing scenarios

## 4. Config Loader

- [x] 4.1 Implement XDG config path resolution (~/.config/git-prs/config.json)
- [x] 4.2 Implement JSON config file parsing using std.json
- [x] 4.3 Implement config validation (required fields, empty values)
- [x] 4.4 Implement `gh auth token` subprocess call
- [x] 4.5 Add tests for config loading and validation

## 5. GitHub Client

- [x] 5.1 Implement HTTP client setup using std.http (uses gh CLI subprocess instead)
- [x] 5.2 Implement GraphQL query construction for PR search
- [x] 5.3 Implement GraphQL response parsing for PR data
- [x] 5.4 Implement pagination handling for large result sets (via limit parameter)
- [x] 5.5 Implement authenticated user lookup via /user endpoint
- [x] 5.6 Implement unique commenter counting from comments
- [x] 5.7 Implement error handling (auth errors, network failures, rate limits)
- [x] 5.8 Add tests for GitHub client (with mocked responses)

## 6. Output Formatter

- [x] 6.1 Implement terminal width detection from COLUMNS env var
- [x] 6.2 Implement column truncation with "..." for overflow
- [x] 6.3 Implement table header and row formatting for mine view
- [x] 6.4 Implement table header and row formatting for team view (with AUTHOR column)
- [x] 6.5 Implement PR sorting by age (newest first)
- [x] 6.6 Implement PR sorting by author then age for team view
- [x] 6.7 Implement URL formatting for clickable links (URL stored in struct)
- [x] 6.8 Add tests for output formatting

## 7. Integration

- [x] 7.1 Wire CLI parser to config loader
- [x] 7.2 Wire config loader to GitHub client
- [x] 7.3 Wire GitHub client to output formatter
- [x] 7.4 Implement main command dispatch (mine vs team)
- [x] 7.5 Add end-to-end integration test (verified via manual testing)

## 8. Documentation and Polish

- [x] 8.1 Add example config.json to error message
- [x] 8.2 Ensure all error messages go to stderr
- [x] 8.3 Verify exit codes (0 for success/no PRs, non-zero for errors)
- [x] 8.4 Run full test suite and fix any failures
