## 1. Update CLI Parser

- [ ] 1.1 Add `json: bool = false` field to MineArgs struct in `src/cli.zig`
- [ ] 1.2 Add `json: bool = false` field to TeamArgs struct in `src/cli.zig`
- [ ] 1.3 Parse `--json` flag in `parseMineArgs` function
- [ ] 1.4 Parse `--json` flag in `parseTeamArgs` function
- [ ] 1.5 Update `printUsage` to document `--json` flag

## 2. Implement JSON Formatter

- [ ] 2.1 Add `formatJsonOutput` function to `src/formatter.zig` using `std.json.stringify`
- [ ] 2.2 Handle empty PR list case (output `[]`)

## 3. Wire Up Main

- [ ] 3.1 Update mine command in `src/main.zig` to check `args.json` and call appropriate formatter
- [ ] 3.2 Update team command in `src/main.zig` to check `args.json` and call appropriate formatter

## 4. Add Tests

- [ ] 4.1 Add CLI parser tests for `--json` flag with mine command
- [ ] 4.2 Add CLI parser tests for `--json` flag with team command
- [ ] 4.3 Add formatter test for JSON output with PRs
- [ ] 4.4 Add formatter test for JSON output with empty list

## 5. Verification

- [ ] 5.1 Run `zig build test` to verify all tests pass
- [ ] 5.2 Manual test: `git-prs mine --json | jq '.'`
- [ ] 5.3 Manual test: `git-prs team --org <org> --json | jq '.[0]'`
