## ADDED Requirements

### Requirement: Detect comment presence across PR list
The formatter SHALL determine whether any PR in a result set has comments by checking if any PR has `unique_commenters > 0`.

#### Scenario: At least one PR has comments
- **WHEN** at least one PR in the list has `unique_commenters > 0`
- **THEN** the detection function returns true (show comments)

#### Scenario: No PRs have comments
- **WHEN** all PRs in the list have `unique_commenters == 0`
- **THEN** the detection function returns false (hide comments)

#### Scenario: Empty PR list
- **WHEN** the PR list is empty
- **THEN** the detection function returns false (hide comments)

### Requirement: Comment detection runs once per output
The formatter SHALL run comment detection once at the start of table output, not per row.

#### Scenario: Detection computed before first row
- **WHEN** formatter begins rendering table output
- **THEN** comment presence is determined before any rows are formatted

#### Scenario: Result passed to row formatting
- **WHEN** formatter renders each PR row
- **THEN** the pre-computed show_comments boolean controls column visibility

## MODIFIED Requirements

(none)

## REMOVED Requirements

(none)
