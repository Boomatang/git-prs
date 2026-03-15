## MODIFIED Requirements

### Requirement: Team org lookup
The team command SHALL match the --org value against configured team orgs using case-insensitive comparison.

#### Scenario: Lowercase flag matches uppercase config key
- **WHEN** config has team for org "MyCompany" and user runs `git-prs team --org mycompany`
- **THEN** the team config for "MyCompany" is used

#### Scenario: Uppercase flag matches lowercase config key
- **WHEN** config has team for org "acme" and user runs `git-prs team --org ACME`
- **THEN** the team config for "acme" is used

#### Scenario: Original config casing preserved for API calls
- **WHEN** config has team for org "GitHub" and user runs `git-prs team --org github`
- **THEN** the API calls use "GitHub" (the config's casing), not "github"

#### Scenario: Error message shows user's input
- **WHEN** user runs `git-prs team --org NONEXISTENT` and no matching org exists
- **THEN** error message includes "NONEXISTENT" (user's input)
