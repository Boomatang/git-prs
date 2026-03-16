## 1. Data Types

- [ ] 1.1 Add SortField enum with values: age, author, repo, comments, last
- [ ] 1.2 Add SortDirection enum with values: asc, desc
- [ ] 1.3 Add SortCriteria struct with field and direction members
- [ ] 1.4 Add sort_criteria slice field to MineArgs, TeamArgs, and MergedArgs structs

## 2. CLI Parsing

- [ ] 2.1 Add --sort parameter to mine_params clap definition with multi support
- [ ] 2.2 Add --sort parameter to team_params clap definition with multi support
- [ ] 2.3 Add --sort parameter to merged_params clap definition with multi support
- [ ] 2.4 Implement parseSortCriteria function to parse "field[:direction]" syntax
- [ ] 2.5 Add InvalidSortField and InvalidSortDirection to ParseError enum
- [ ] 2.6 Add InvalidSortFieldForCommand error for mine + author validation
- [ ] 2.7 Wire up sort criteria parsing in parseMineCommand
- [ ] 2.8 Wire up sort criteria parsing in parseTeamCommand
- [ ] 2.9 Wire up sort criteria parsing in parseMergedCommand
- [ ] 2.10 Add validation to reject --sort author for mine command

## 3. Sort Implementation

- [ ] 3.1 Add comparePRs function that compares two PRs by a single SortCriteria
- [ ] 3.2 Implement null-as-smallest logic for last_comment_at field comparison
- [ ] 3.3 Add multiCriteriaSort function that applies slice of SortCriteria
- [ ] 3.4 Update formatMineOutput signature to accept optional sort_criteria parameter
- [ ] 3.5 Update formatTeamOutput signature to accept optional sort_criteria parameter
- [ ] 3.6 Apply default sort criteria when none provided (mine: age:desc, team: author:asc + age:desc)

## 4. Integration

- [ ] 4.1 Update mine command handler to pass sort_criteria to formatMineOutput
- [ ] 4.2 Update team command handler to pass sort_criteria to formatTeamOutput
- [ ] 4.3 Update merged command handler to pass sort_criteria to formatter

## 5. Help Text

- [ ] 5.1 Update printMineHelp to document --sort flag and available fields
- [ ] 5.2 Update printTeamHelp to document --sort flag and available fields
- [ ] 5.3 Update printMergedHelp to document --sort flag and available fields

## 6. Testing

- [ ] 6.1 Add CLI parser tests for --sort flag parsing with various formats
- [ ] 6.2 Add CLI parser tests for invalid sort field/direction errors
- [ ] 6.3 Add CLI parser test for mine + author rejection
- [ ] 6.4 Add formatter tests for single-criteria sorting
- [ ] 6.5 Add formatter tests for multi-criteria sorting with tie-breaking
- [ ] 6.6 Add formatter tests for null handling in last field sorting
