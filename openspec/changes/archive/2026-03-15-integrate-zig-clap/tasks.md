## 1. Add zig-clap dependency

- [x] 1.1 Add zig-clap to build.zig.zon using `zig fetch --save`
- [x] 1.2 Update build.zig to add clap module to executable

## 2. Implement clap-based parameter definitions

- [x] 2.1 Create custom date parser function for YYYY-MM-DD validation
- [x] 2.2 Define mine command parameters using clap.parseParamsComptime
- [x] 2.3 Define team command parameters using clap.parseParamsComptime
- [x] 2.4 Define merged command parameters using clap.parseParamsComptime
- [x] 2.5 Define global parameters (--help, --version, --json)

## 3. Implement new parseArgs function

- [x] 3.1 Create new parseArgs implementation using clap.parse()
- [x] 3.2 Implement subcommand dispatch based on first positional argument
- [x] 3.3 Map clap parse results to existing MineArgs struct
- [x] 3.4 Map clap parse results to existing TeamArgs struct
- [x] 3.5 Map clap parse results to existing MergedArgs struct
- [x] 3.6 Implement mutual exclusivity validation for merged --days vs --since/--until

## 4. Remove manual parsing code

- [x] 4.1 Remove parseMineArgs function
- [x] 4.2 Remove parseTeamArgs function
- [x] 4.3 Remove parseMergedArgs function
- [x] 4.4 Remove printUsage function
- [x] 4.5 Remove hasFlag helper function

## 5. Update tests

- [x] 5.1 Update existing CLI parser tests to work with new implementation
- [x] 5.2 Add tests for clap-generated help output
- [x] 5.3 Verify all existing test scenarios still pass

## 6. Verification

- [x] 6.1 Run full test suite with `zig build test`
- [x] 6.2 Manual testing of all commands with various flag combinations
- [x] 6.3 Verify help output matches expected format
