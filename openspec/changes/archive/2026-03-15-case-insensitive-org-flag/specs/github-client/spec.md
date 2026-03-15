## MODIFIED Requirements

### Requirement: Org filter matching
The github client SHALL match the org filter value against configured orgs using case-insensitive comparison.

#### Scenario: Lowercase filter matches uppercase config
- **WHEN** config has org "Kubernetes" and user specifies `--org kubernetes`
- **THEN** the filter matches and PRs from "Kubernetes" are included

#### Scenario: Uppercase filter matches lowercase config
- **WHEN** config has org "mycompany" and user specifies `--org MyCompany`
- **THEN** the filter matches and PRs from "mycompany" are included

#### Scenario: Mixed case filter matches
- **WHEN** config has org "GitHub" and user specifies `--org github`
- **THEN** the filter matches and PRs from "GitHub" are included

#### Scenario: Exact case still works
- **WHEN** config has org "kubernetes" and user specifies `--org kubernetes`
- **THEN** the filter matches and PRs from "kubernetes" are included
