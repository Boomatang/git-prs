## MODIFIED Requirements

### Requirement: CLI reference reflects current command set

The cli-reference.md SHALL accurately document all current commands and their options.

#### Scenario: User finds all commands documented
- **WHEN** a user reads cli-reference.md
- **THEN** they find documentation for `mine`, `team`, and `merged` commands
- **THEN** each command section includes current syntax, options, and descriptions

#### Scenario: User finds display features documented
- **WHEN** a user reads cli-reference.md
- **THEN** they find a section describing visual display features
- **THEN** the section mentions draft PR styling (dim+italic), dynamic column widths, and inline URL display on wide terminals

### Requirement: Config guide reflects current configuration options

The config-guide.md SHALL accurately document all current configuration options.

#### Scenario: User finds current config format documented
- **WHEN** a user reads config-guide.md
- **THEN** the primary examples show the named teams configuration format
- **THEN** the document explains both legacy (`team` object) and named teams (`teams` object) formats

### Requirement: README features list is current

The README.md features list SHALL reflect all major capabilities of the tool.

#### Scenario: User finds comprehensive features list
- **WHEN** a user reads the README.md Features section
- **THEN** the list includes viewing own PRs, team PRs, merged PRs, date filtering, named teams, JSON output, and display features
