## ADDED Requirements

### Requirement: Named teams configuration structure
The config SHALL support a `teams` key containing named team definitions with explicit orgs and members.

#### Scenario: Valid teams configuration
- **WHEN** config contains `teams` with named team objects
- **THEN** each team object SHALL have `orgs` array and `members` array

#### Scenario: Team with optional date filters
- **WHEN** a team definition includes `since` or `until` fields
- **THEN** the values SHALL be validated as YYYY-MM-DD format

### Requirement: Explicit orgs per team
Each team definition SHALL include an explicit `orgs` array listing the GitHub organizations to search.

#### Scenario: Team with multiple orgs
- **WHEN** a team has `orgs: ["org-a", "org-b"]`
- **THEN** the system searches both orgs for PRs by team members

#### Scenario: Missing orgs field
- **WHEN** a team definition omits the `orgs` field
- **THEN** the system SHALL return a configuration error

### Requirement: Non-empty orgs and members
The `orgs` and `members` arrays SHALL NOT be empty.

#### Scenario: Empty orgs array
- **WHEN** a team has `orgs: []`
- **THEN** the system SHALL return a configuration error

#### Scenario: Empty members array
- **WHEN** a team has `members: []`
- **THEN** the system SHALL return a configuration error

### Requirement: Default team reference
The `teams` object MAY contain a `default` key that references another team by name.

#### Scenario: Valid default reference
- **WHEN** `teams.default` is set to "release" and a team named "release" exists
- **THEN** the configuration is valid

#### Scenario: Invalid default reference
- **WHEN** `teams.default` references a team name that does not exist
- **THEN** the system SHALL return a configuration error

### Requirement: Default required for multiple teams
When multiple teams are defined and no `default` is specified, the system SHALL require an explicit team name on the command line.

#### Scenario: Multiple teams without default
- **WHEN** config has multiple teams and no `default` key
- **THEN** running `git_prs team` without a team name SHALL return an error
