## ADDED Requirements

### Requirement: Draft status data field

The `PullRequest` struct SHALL include an `is_draft` boolean field indicating whether the PR is a draft.

#### Scenario: Draft PR fetched from API
- **WHEN** a draft PR is fetched from GitHub
- **THEN** the `is_draft` field SHALL be `true`

#### Scenario: Ready PR fetched from API
- **WHEN** a non-draft PR is fetched from GitHub
- **THEN** the `is_draft` field SHALL be `false`

### Requirement: Draft rows styled with dim and italic

Draft PR rows SHALL be displayed with ANSI dim + italic styling (`\x1b[2;3m` prefix, `\x1b[0m` suffix) when output is to a TTY.

#### Scenario: Draft PR displayed to terminal
- **WHEN** a draft PR is displayed AND stdout is a TTY
- **THEN** the entire row SHALL be wrapped with `\x1b[2;3m` prefix and `\x1b[0m` suffix

#### Scenario: Ready PR displayed to terminal
- **WHEN** a non-draft PR is displayed AND stdout is a TTY
- **THEN** the row SHALL NOT include ANSI styling codes

### Requirement: No ANSI codes in piped output

ANSI escape codes SHALL NOT be emitted when stdout is not a TTY.

#### Scenario: Draft PR in piped output
- **WHEN** a draft PR is displayed AND stdout is NOT a TTY
- **THEN** the row SHALL NOT include any ANSI escape codes

#### Scenario: Output redirected to file
- **WHEN** output is redirected to a file
- **THEN** no ANSI escape codes SHALL appear in the output

### Requirement: Draft status in JSON output

The JSON output format SHALL include an `is_draft` boolean field for each PR.

#### Scenario: Draft PR in JSON output
- **WHEN** JSON output is requested for a draft PR
- **THEN** the PR object SHALL include `"is_draft": true`

#### Scenario: Ready PR in JSON output
- **WHEN** JSON output is requested for a non-draft PR
- **THEN** the PR object SHALL include `"is_draft": false`

### Requirement: Styling applies to both views

Draft PR styling SHALL apply consistently to both `mine` and `team` command outputs.

#### Scenario: Draft in mine view
- **WHEN** the `mine` command displays a draft PR to a TTY
- **THEN** the row SHALL be styled with dim + italic

#### Scenario: Draft in team view
- **WHEN** the `team` command displays a draft PR to a TTY
- **THEN** the row SHALL be styled with dim + italic
