## ADDED Requirements

### Requirement: Merged command documentation in CLI reference

The cli-reference.md SHALL include a complete section documenting the `merged` command with syntax, all options, description, and examples.

#### Scenario: User reads merged command documentation
- **WHEN** a user opens docs/cli-reference.md
- **THEN** they find a "git-prs merged" section with syntax block showing `git-prs merged [OPTIONS]`
- **THEN** the section lists `--days`, `--since`, `--until`, `--org`, and `--json` options with descriptions
- **THEN** the section explains this command shows recently merged PRs authored by the user

#### Scenario: User finds merged command examples
- **WHEN** a user looks at the Examples section
- **THEN** they find examples for `git-prs merged`, `git-prs merged --days 14`, and date range filtering

### Requirement: Merged command mentioned in README

The README.md features list SHALL mention the ability to view merged PRs.

#### Scenario: User discovers merged PRs feature in README
- **WHEN** a user reads the README.md Features section
- **THEN** they see a bullet point describing the merged PRs capability
