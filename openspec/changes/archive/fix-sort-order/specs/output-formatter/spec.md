## MODIFIED Requirements

### Requirement: Sort PRs by age
The output formatter SHALL sort PRs with newest first.

#### Scenario: Sort order
- **WHEN** formatter receives PRs with ages 1d, 5d, 2d
- **THEN** formatter outputs in order: 1d, 2d, 5d (newest first)

### Requirement: Sort by author then age
The output formatter SHALL sort PRs by author then by age (newest first within each author).

#### Scenario: Sort by author then age
- **WHEN** PRs are from multiple team members
- **THEN** formatter groups PRs by author with newest PRs first within each group
