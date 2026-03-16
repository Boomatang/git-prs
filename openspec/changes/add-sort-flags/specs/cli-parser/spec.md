## ADDED Requirements

### Requirement: Parse --sort flag for mine command
The CLI parser SHALL accept `--sort <field>[:direction]` flags for the mine command, supporting multiple occurrences.

#### Scenario: Mine with single sort flag
- **WHEN** user runs `git-prs mine --sort age:desc`
- **THEN** parser returns MineArgs with sort_criteria containing [age:desc]

#### Scenario: Mine with multiple sort flags
- **WHEN** user runs `git-prs mine --sort repo --sort age:desc`
- **THEN** parser returns MineArgs with sort_criteria containing [repo:asc, age:desc]

#### Scenario: Mine with sort and other flags
- **WHEN** user runs `git-prs mine --org kubernetes --sort age --limit 10`
- **THEN** parser returns MineArgs with org_filter="kubernetes", limit=10, and sort_criteria containing [age:asc]

### Requirement: Parse --sort flag for team command
The CLI parser SHALL accept `--sort <field>[:direction]` flags for the team command, supporting multiple occurrences.

#### Scenario: Team with single sort flag
- **WHEN** user runs `git-prs team --sort author`
- **THEN** parser returns TeamArgs with sort_criteria containing [author:asc]

#### Scenario: Team with multiple sort flags
- **WHEN** user runs `git-prs team --sort repo:desc --sort age:asc`
- **THEN** parser returns TeamArgs with sort_criteria containing [repo:desc, age:asc]

### Requirement: Parse --sort flag for merged command
The CLI parser SHALL accept `--sort <field>[:direction]` flags for the merged command, supporting multiple occurrences.

#### Scenario: Merged with single sort flag
- **WHEN** user runs `git-prs merged --sort age`
- **THEN** parser returns MergedArgs with sort_criteria containing [age:asc]

#### Scenario: Merged with sort and days flag
- **WHEN** user runs `git-prs merged --days 14 --sort repo`
- **THEN** parser returns MergedArgs with days=14 and sort_criteria containing [repo:asc]

### Requirement: SortField and SortDirection types
The CLI parser SHALL define SortField enum with values `age`, `author`, `repo`, `comments`, `last` and SortDirection enum with values `asc`, `desc`.

#### Scenario: SortCriteria structure
- **WHEN** parser parses `--sort age:desc`
- **THEN** result contains SortCriteria with field=SortField.age and direction=SortDirection.desc

### Requirement: Reject author sort for mine command
The CLI parser SHALL return an error when `--sort author` is specified for the mine command.

#### Scenario: Author sort rejected for mine
- **WHEN** user runs `git-prs mine --sort author`
- **THEN** parser returns InvalidSortFieldForCommand error

#### Scenario: Author sort rejected for mine with direction
- **WHEN** user runs `git-prs mine --sort author:desc`
- **THEN** parser returns InvalidSortFieldForCommand error
