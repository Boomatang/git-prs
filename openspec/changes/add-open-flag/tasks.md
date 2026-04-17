# Tasks: --open Flag

## 1. CLI Parsing

- [ ] Add `open: bool = false` to `MineArgs` struct
- [ ] Add `open: bool = false` to `TeamArgs` struct
- [ ] Add `open: bool = false` to `MergedArgs` struct
- [ ] Add `--open` to `mine_params` clap definition
- [ ] Add `--open` to `team_params` clap definition
- [ ] Add `--open` to `merged_params` clap definition
- [ ] Add `OpenWithJson` to `ParseError` enum
- [ ] Add validation in `parseMineCommand`: error if both `--open` and `--json`
- [ ] Add validation in `parseTeamCommand`: error if both `--open` and `--json`
- [ ] Add validation in `parseMergedCommand`: error if both `--open` and `--json`
- [ ] Update `printMineHelp` with `--open` documentation
- [ ] Update `printTeamHelp` with `--open` documentation
- [ ] Update `printMergedHelp` with `--open` documentation

## 2. Browser Module

- [ ] Create `src/browser.zig`
- [ ] Implement `openUrl` function with platform detection
- [ ] Use `std.process.Child` to spawn browser command
- [ ] Handle spawn errors gracefully
- [ ] Export from `src/root.zig`

## 3. Command Handlers

- [ ] Add `OpenWithJson` error handling in `main.zig` error switch
- [ ] Implement `--open` handling in `runMineCommand`
- [ ] Implement `--open` handling in `runTeamCommand`
- [ ] Implement `--open` handling in `runMergedCommand`
- [ ] Print "Opening N PRs..." feedback message
- [ ] Print "No PRs to open" for empty results

## 4. Tests

- [ ] Test: `mine --open` parses correctly
- [ ] Test: `team --open` parses correctly
- [ ] Test: `merged --open` parses correctly
- [ ] Test: `mine --open --json` returns `OpenWithJson` error
- [ ] Test: `team --open --json` returns `OpenWithJson` error
- [ ] Test: `merged --open --json` returns `OpenWithJson` error
- [ ] Test: `--open` works with `--org` filter
- [ ] Test: `--open` works with `--member` filter
- [ ] Test: `--open` works with `--since`/`--until`

## 5. Documentation

- [ ] Update main `printUsage` if needed
