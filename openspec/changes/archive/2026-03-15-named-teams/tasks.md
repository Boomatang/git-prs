## 1. Config Data Structures

- [x] 1.1 Add `NamedTeamConfig` struct with `orgs`, `members`, `since`, `until` fields
- [x] 1.2 Add `TeamsConfig` struct with `default` and `teams` hashmap
- [x] 1.3 Update `Config` struct to use new `TeamsConfig` instead of old team structure
- [x] 1.4 Add new error types: `EmptyTeamOrgs`, `MissingTeamOrgs`, `InvalidDefaultTeam`, `NoDefaultTeam`

## 2. Config Parsing

- [x] 2.1 Implement `parseTeamsConfig` function for new `teams` structure
- [x] 2.2 Parse `default` field from teams object
- [x] 2.3 Parse named team objects with `orgs` and `members` arrays
- [x] 2.4 Parse optional `since` and `until` date fields per team
- [x] 2.5 Validate `orgs` array is present and non-empty
- [x] 2.6 Validate `members` array is present and non-empty
- [x] 2.7 Validate `default` references an existing team name
- [x] 2.8 Remove old `parseTeams` function and `TeamConfig` struct

## 3. CLI Changes

- [x] 3.1 Add optional positional argument for team name to `team` subcommand
- [x] 3.2 Pass team name argument to main team handler

## 4. Team Selection Logic

- [x] 4.1 Implement team selection: explicit name takes priority
- [x] 4.2 Implement default team fallback when no name provided
- [x] 4.3 Implement single-team auto-selection when only one team exists
- [x] 4.4 Implement error for multiple teams with no default and no argument
- [x] 4.5 Update team PR fetching to use selected team's orgs and members

## 5. Config Cleanup

- [x] 5.1 Update `Config.deinit` for new teams structure
- [x] 5.2 Update config error messages for new error types
- [x] 5.3 Update example config in `printConfigNotFoundError`

## 6. Tests

- [x] 6.1 Add tests for valid teams config parsing
- [x] 6.2 Add tests for empty orgs validation error
- [x] 6.3 Add tests for empty members validation error
- [x] 6.4 Add tests for missing orgs validation error
- [x] 6.5 Add tests for invalid default reference error
- [x] 6.6 Add tests for single team auto-selection
- [x] 6.7 Add tests for default team selection
- [x] 6.8 Add tests for explicit team name selection
- [x] 6.9 Add tests for multiple teams without default error
- [x] 6.10 Remove old team parsing tests

## 7. Verification

- [x] 7.1 Run full test suite
- [x] 7.2 Manual test with single team config
- [x] 7.3 Manual test with multiple teams and default
- [x] 7.4 Manual test with explicit team name argument
- [x] 7.5 Manual test error cases (missing team, no default)
