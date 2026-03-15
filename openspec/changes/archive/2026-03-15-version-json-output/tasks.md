## 1. Update CLI Parser

- [x] 1.1 Change version command type from simple tag to struct with `json: bool` field
- [x] 1.2 Add helper function to scan all args for a specific flag
- [x] 1.3 Update parseArgs to scan for `--version` in all args before subcommand parsing
- [x] 1.4 When `--version` found, also scan for `--json` and return version command with json field

## 2. Update Version Output

- [x] 2.1 Update main.zig version handler to check json flag
- [x] 2.2 Implement JSON output format: `{"name":"git-prs","version":"0.1.0"}`
- [x] 2.3 Keep plain text output as default when json=false

## 3. Testing

- [x] 3.1 Add test for `--version` returning version command with json=false
- [x] 3.2 Add test for `--version --json` returning version command with json=true
- [x] 3.3 Add test for `--json --version` (reversed order) returning version command with json=true
- [x] 3.4 Add test for `mine --version` returning version command (not mine)
- [x] 3.5 Add test for `mine --json --version` returning version command with json=true
- [x] 3.6 Run full test suite to verify no regressions
