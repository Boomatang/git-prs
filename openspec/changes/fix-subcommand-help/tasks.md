## 1. CLI Parser Changes

- [ ] 1.1 Add `HelpTarget` enum to cli.zig with variants: main, mine, team, merged
- [ ] 1.2 Change `Command.help` from `void` to `HelpTarget`
- [ ] 1.3 Update `parseArgs` to return `.{ .help = .main }` for top-level help
- [ ] 1.4 Update `parseMineCommand` to return `.{ .help = .mine }` when help flag detected
- [ ] 1.5 Update `parseTeamCommand` to return `.{ .help = .team }` when help flag detected
- [ ] 1.6 Update `parseMergedCommand` to return `.{ .help = .merged }` when help flag detected

## 2. Main Entry Point

- [ ] 2.1 Update help case in main.zig switch to dispatch based on HelpTarget value
- [ ] 2.2 Call `printMineHelp` for .mine, `printTeamHelp` for .team, `printMergedHelp` for .merged, `printUsage` for .main

## 3. Tests

- [ ] 3.1 Update existing help tests to use new enum syntax (e.g., `.{ .help = .main }`)
- [ ] 3.2 Add test for `mine --help` returning `.{ .help = .mine }`
- [ ] 3.3 Add test for `team --help` returning `.{ .help = .team }`
- [ ] 3.4 Add test for `merged --help` returning `.{ .help = .merged }`

## 4. Verification

- [ ] 4.1 Run `zig build test` to verify all tests pass
- [ ] 4.2 Manual test: `git-prs --help` shows top-level help
- [ ] 4.3 Manual test: `git-prs mine --help` shows mine-specific help
- [ ] 4.4 Manual test: `git-prs team --help` shows team-specific help
- [ ] 4.5 Manual test: `git-prs merged --help` shows merged-specific help
