## ADDED Requirements

### Requirement: Named teams CLI usage documented

The cli-reference.md team command section SHALL document the positional team name argument.

#### Scenario: User reads named teams CLI syntax
- **WHEN** a user reads the team command section in cli-reference.md
- **THEN** the syntax shows `git-prs team [name] [OPTIONS]` with the optional team name argument
- **THEN** the description explains that `[name]` selects a named team from configuration
- **THEN** the documentation explains auto-selection behavior when name is omitted

### Requirement: Named teams examples provided

The cli-reference.md examples section SHALL include named teams usage examples.

#### Scenario: User finds named teams examples
- **WHEN** a user looks at the Examples section
- **THEN** they find examples like `git-prs team release` showing named team selection
- **THEN** they find examples combining team name with other options like `--member`

### Requirement: Named teams configuration documented

The config-guide.md SHALL document the named teams configuration structure.

#### Scenario: User reads named teams configuration format
- **WHEN** a user reads the config-guide.md
- **THEN** they find documentation for the `teams` object structure with named teams
- **THEN** they see that each team can have `orgs` (array), `members` (array), and optional `default` (boolean)
- **THEN** they find a complete example showing multiple named teams with different organizations

### Requirement: Named teams multi-org support documented

The config-guide.md SHALL explain that teams can span multiple organizations.

#### Scenario: User learns about multi-org teams
- **WHEN** a user reads the named teams configuration section
- **THEN** they understand that a single named team can query PRs from multiple orgs
- **THEN** they see an example demonstrating a team with multiple orgs in the `orgs` array

### Requirement: Named teams mentioned in README

The README.md features list SHALL mention named teams capability.

#### Scenario: User discovers named teams in README
- **WHEN** a user reads the README.md Features section
- **THEN** they see a mention of named teams for organizing team queries
