## 1. Project Structure Setup

- [ ] 1.1 Create module files: cli.zig, config.zig, github.zig, formatter.zig, time.zig
- [ ] 1.2 Update main.zig to import and wire together modules
- [ ] 1.3 Update build.zig to include new source files in module

## 2. Time Formatting Utilities

- [ ] 2.1 Implement duration formatting function (minutes, hours, days, weeks, months)
- [ ] 2.2 Add tests for time formatting edge cases

## 3. CLI Parser

- [ ] 3.1 Define Command union type with MineArgs and TeamArgs structs
- [ ] 3.2 Implement argument parsing for `mine` command with --org and --limit flags
- [ ] 3.3 Implement argument parsing for `team` command with --org and --member flags
- [ ] 3.4 Implement --help flag and usage output
- [ ] 3.5 Add error handling for invalid commands and flags
- [ ] 3.6 Add tests for CLI parsing scenarios

## 4. Config Loader

- [ ] 4.1 Implement XDG config path resolution (~/.config/git-prs/config.json)
- [ ] 4.2 Implement JSON config file parsing using std.json
- [ ] 4.3 Implement config validation (required fields, empty values)
- [ ] 4.4 Implement `gh auth token` subprocess call
- [ ] 4.5 Add tests for config loading and validation

## 5. GitHub Client

- [ ] 5.1 Implement HTTP client setup using std.http
- [ ] 5.2 Implement GraphQL query construction for PR search
- [ ] 5.3 Implement GraphQL response parsing for PR data
- [ ] 5.4 Implement pagination handling for large result sets
- [ ] 5.5 Implement authenticated user lookup via /user endpoint
- [ ] 5.6 Implement unique commenter counting from comments
- [ ] 5.7 Implement error handling (auth errors, network failures, rate limits)
- [ ] 5.8 Add tests for GitHub client (with mocked responses)

## 6. Output Formatter

- [ ] 6.1 Implement terminal width detection from COLUMNS env var
- [ ] 6.2 Implement column truncation with "..." for overflow
- [ ] 6.3 Implement table header and row formatting for mine view
- [ ] 6.4 Implement table header and row formatting for team view (with AUTHOR column)
- [ ] 6.5 Implement PR sorting by age (oldest first)
- [ ] 6.6 Implement PR sorting by author then age for team view
- [ ] 6.7 Implement URL formatting for clickable links
- [ ] 6.8 Add tests for output formatting

## 7. Integration

- [ ] 7.1 Wire CLI parser to config loader
- [ ] 7.2 Wire config loader to GitHub client
- [ ] 7.3 Wire GitHub client to output formatter
- [ ] 7.4 Implement main command dispatch (mine vs team)
- [ ] 7.5 Add end-to-end integration test

## 8. Documentation and Polish

- [ ] 8.1 Add example config.json to error message
- [ ] 8.2 Ensure all error messages go to stderr
- [ ] 8.3 Verify exit codes (0 for success/no PRs, non-zero for errors)
- [ ] 8.4 Run full test suite and fix any failures
