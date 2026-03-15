## ADDED Requirements

### Requirement: JSON output format
The system SHALL output PR data as a JSON array when `--json` flag is specified.

#### Scenario: Mine command with --json flag
- **WHEN** user runs `git-prs mine --json`
- **THEN** output is a valid JSON array of PR objects

#### Scenario: Team command with --json flag
- **WHEN** user runs `git-prs team --org mycompany --json`
- **THEN** output is a valid JSON array of PR objects

#### Scenario: Empty result with --json
- **WHEN** user runs command with `--json` and no PRs are found
- **THEN** output is an empty JSON array `[]`

### Requirement: JSON PR object structure
Each PR object in the JSON output SHALL include all PR fields.

#### Scenario: PR object contains required fields
- **WHEN** a PR is serialized to JSON
- **THEN** the object contains: org, repo, number, title, url, author, created_at, last_comment_at, unique_commenters

#### Scenario: Null handling for optional fields
- **WHEN** a PR has no comments (last_comment_at is null)
- **THEN** the JSON object has `"last_comment_at": null`

### Requirement: JSON output excludes table formatting
The JSON output SHALL NOT include table headers, separators, or padding.

#### Scenario: Clean JSON output
- **WHEN** user runs `git-prs mine --json`
- **THEN** output contains only the JSON array with no other text
