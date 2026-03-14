## 1. Config Parsing Changes

- [ ] 1.1 Add TeamConfig struct with members, since, and until fields in config.zig
- [ ] 1.2 Add date parsing helper function for YYYY-MM-DD format
- [ ] 1.3 Update parseTeams to parse object format instead of array
- [ ] 1.4 Add InvalidDateFormat error to ConfigError enum
- [ ] 1.5 Update printConfigNotFoundError with new config format example
- [ ] 1.6 Add tests for new team config parsing (valid dates, missing dates, invalid dates)

## 2. CLI Argument Parsing

- [ ] 2.1 Add since and until fields to MineArgs struct in cli.zig
- [ ] 2.2 Add since and until fields to TeamArgs struct in cli.zig
- [ ] 2.3 Add --since and --until flag parsing to parseMineArgs
- [ ] 2.4 Add --since and --until flag parsing to parseTeamArgs
- [ ] 2.5 Add InvalidDateValue error to ParseError enum
- [ ] 2.6 Update printUsage with new --since and --until flags
- [ ] 2.7 Add tests for CLI date flag parsing

## 3. GitHub Query Integration

- [ ] 3.1 Update fetchPRsWithGh signature to accept optional since and until dates
- [ ] 3.2 Modify search query building to append created:>=YYYY-MM-DD when since is provided
- [ ] 3.3 Modify search query building to append created:<=YYYY-MM-DD when until is provided
- [ ] 3.4 Update fetchTeamPRs to pass date range from config/CLI
- [ ] 3.5 Update fetchUserPRs to pass date range from CLI

## 4. Main Integration

- [ ] 4.1 Update main.zig to resolve effective dates (CLI override > config > none) for team command
- [ ] 4.2 Update main.zig to pass CLI dates to mine command
- [ ] 4.3 Build and verify all tests pass

## 5. Manual Testing

- [ ] 5.1 Test team command with config dates only
- [ ] 5.2 Test team command with CLI date override
- [ ] 5.3 Test mine command with --since flag
- [ ] 5.4 Test mine command with --until flag
- [ ] 5.5 Test error handling for invalid date formats
