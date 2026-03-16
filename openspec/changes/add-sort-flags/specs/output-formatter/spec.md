## ADDED Requirements

### Requirement: Accept sort criteria parameter
The formatMineOutput and formatTeamOutput functions SHALL accept an optional sort criteria parameter to control PR ordering.

#### Scenario: Mine output with custom sort
- **WHEN** formatMineOutput is called with sort_criteria=[repo:asc, age:desc]
- **THEN** output PRs are sorted by repo ascending, then by age descending within each repo

#### Scenario: Team output with custom sort
- **WHEN** formatTeamOutput is called with sort_criteria=[age:asc]
- **THEN** output PRs are sorted by age ascending (oldest first)

#### Scenario: Mine output with no sort criteria
- **WHEN** formatMineOutput is called with empty sort_criteria
- **THEN** output PRs are sorted by age descending (default behavior)

#### Scenario: Team output with no sort criteria
- **WHEN** formatTeamOutput is called with empty sort_criteria
- **THEN** output PRs are sorted by author ascending, then age descending (default behavior)

### Requirement: Generic multi-criteria sort function
The formatter SHALL implement a generic sort function that applies multiple sort criteria in order.

#### Scenario: Single criterion sort
- **WHEN** sorting with criteria=[age:asc]
- **THEN** PRs are ordered by created_at ascending

#### Scenario: Multi-criteria tie-breaking
- **WHEN** sorting with criteria=[author:asc, age:desc] and two PRs have same author
- **THEN** those PRs are ordered by age descending relative to each other

### Requirement: Sort by repo field
The formatter SHALL support sorting by the combined org/repo identifier.

#### Scenario: Repo ascending sort
- **WHEN** sorting with criteria=[repo:asc]
- **THEN** PRs are ordered alphabetically by "org/repo" string

#### Scenario: Repo descending sort
- **WHEN** sorting with criteria=[repo:desc]
- **THEN** PRs are ordered reverse-alphabetically by "org/repo" string

### Requirement: Sort by comments field
The formatter SHALL support sorting by the unique_commenters count.

#### Scenario: Comments ascending sort
- **WHEN** sorting with criteria=[comments:asc]
- **THEN** PRs are ordered by unique_commenters count, lowest first

#### Scenario: Comments descending sort
- **WHEN** sorting with criteria=[comments:desc]
- **THEN** PRs are ordered by unique_commenters count, highest first

### Requirement: Sort by last field with null handling
The formatter SHALL support sorting by last_comment_at, treating null values as smallest.

#### Scenario: Last ascending with nulls
- **WHEN** sorting with criteria=[last:asc] and some PRs have null last_comment_at
- **THEN** PRs with null last_comment_at appear first, followed by PRs ordered by last_comment_at ascending

#### Scenario: Last descending with nulls
- **WHEN** sorting with criteria=[last:desc] and some PRs have null last_comment_at
- **THEN** PRs are ordered by last_comment_at descending, with null last_comment_at PRs appearing last

## MODIFIED Requirements

### Requirement: Sort PRs by age descending (newest first)
The formatMineOutput function SHALL sort PRs by age descending (newest first) when no sort criteria is provided.

#### Scenario: Default mine sort order
- **WHEN** formatMineOutput is called with empty sort_criteria
- **THEN** PRs are sorted with newest (highest created_at) first

### Requirement: Sort PRs by author then age
The formatTeamOutput function SHALL sort PRs by author alphabetically, then by age descending within each author when no sort criteria is provided.

#### Scenario: Default team sort order
- **WHEN** formatTeamOutput is called with empty sort_criteria
- **THEN** PRs are sorted alphabetically by author, and within same author sorted by age descending
