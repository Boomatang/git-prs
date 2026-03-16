## ADDED Requirements

### Requirement: Sort flag syntax
The CLI SHALL accept `--sort <field>[:direction]` flags where field is one of `age`, `author`, `repo`, `comments`, `last` and direction is `asc` or `desc`.

#### Scenario: Sort with explicit direction
- **WHEN** user runs `git-prs mine --sort age:desc`
- **THEN** parser returns sort criteria with field=age and direction=desc

#### Scenario: Sort with default direction
- **WHEN** user runs `git-prs mine --sort age`
- **THEN** parser returns sort criteria with field=age and direction=asc

#### Scenario: Invalid sort field rejected
- **WHEN** user runs `git-prs mine --sort invalid`
- **THEN** parser returns InvalidSortField error

#### Scenario: Invalid sort direction rejected
- **WHEN** user runs `git-prs mine --sort age:sideways`
- **THEN** parser returns InvalidSortDirection error

### Requirement: Multiple sort flags
The CLI SHALL accept multiple `--sort` flags and apply them in order as primary, secondary, etc. sort criteria.

#### Scenario: Two sort criteria
- **WHEN** user runs `git-prs team --sort repo --sort age:desc`
- **THEN** parser returns sort criteria array with [repo:asc, age:desc] in that order

#### Scenario: Three sort criteria
- **WHEN** user runs `git-prs team --sort author --sort repo --sort age`
- **THEN** parser returns sort criteria array with [author:asc, repo:asc, age:asc] in order

### Requirement: Sort field validation per command
The CLI SHALL validate that sort fields are applicable to the command being executed.

#### Scenario: Author sort rejected for mine command
- **WHEN** user runs `git-prs mine --sort author`
- **THEN** parser returns InvalidSortFieldForCommand error with message indicating author is not valid for mine

#### Scenario: Author sort accepted for team command
- **WHEN** user runs `git-prs team --sort author`
- **THEN** parser returns TeamArgs with sort criteria containing author:asc

#### Scenario: Author sort accepted for merged command
- **WHEN** user runs `git-prs merged --sort author`
- **THEN** parser returns MergedArgs with sort criteria containing author:asc

### Requirement: Default sort order when no flags provided
The CLI SHALL use command-specific default sort order when no `--sort` flags are provided.

#### Scenario: Mine default sort
- **WHEN** user runs `git-prs mine` without --sort flags
- **THEN** PRs are sorted by age descending (newest first)

#### Scenario: Team default sort
- **WHEN** user runs `git-prs team` without --sort flags
- **THEN** PRs are sorted by author ascending, then by age descending

#### Scenario: Merged default sort
- **WHEN** user runs `git-prs merged` without --sort flags
- **THEN** PRs are sorted by age descending (newest first)

### Requirement: Null handling in last field sorting
The formatter SHALL treat null values in the `last` (last_comment_at) field as the smallest value when sorting.

#### Scenario: Nulls first in ascending sort
- **WHEN** PRs are sorted by `--sort last:asc`
- **THEN** PRs with no comments (null last_comment_at) appear before PRs with comments

#### Scenario: Nulls last in descending sort
- **WHEN** PRs are sorted by `--sort last:desc`
- **THEN** PRs with no comments (null last_comment_at) appear after PRs with comments

### Requirement: Multi-criteria sort application
The formatter SHALL apply sort criteria in order, using subsequent criteria to break ties.

#### Scenario: Secondary sort breaks ties
- **WHEN** PRs are sorted with `--sort repo --sort age:desc`
- **THEN** PRs in the same repo are ordered by age descending within that group

#### Scenario: Tertiary sort breaks remaining ties
- **WHEN** PRs are sorted with `--sort author --sort repo --sort age`
- **THEN** PRs by same author in same repo are ordered by age ascending

### Requirement: Sort criteria in help output
The CLI help text SHALL document the --sort flag syntax, available fields, and default behavior.

#### Scenario: Mine help shows sort options
- **WHEN** user runs `git-prs mine --help`
- **THEN** output includes documentation for --sort flag with available fields (age, repo, comments, last) and direction syntax

#### Scenario: Team help shows sort options
- **WHEN** user runs `git-prs team --help`
- **THEN** output includes documentation for --sort flag with available fields (age, author, repo, comments, last) and direction syntax
