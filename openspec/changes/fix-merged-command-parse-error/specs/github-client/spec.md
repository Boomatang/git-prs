## MODIFIED Requirements

### Requirement: Merged PRs GraphQL query includes all required fields

The `fetchMergedPRsWithGh` function SHALL request all fields required by `parsePullRequestFromGraphQL`, including `isDraft`.

#### Scenario: Merged command returns PR data successfully
- **WHEN** user runs `git-prs merged`
- **THEN** the command fetches merged PRs from GitHub API without parse errors
- **THEN** each PR includes draft status information

#### Scenario: Merged PRs query matches other PR queries
- **WHEN** `fetchMergedPRsWithGh` constructs a GraphQL query
- **THEN** the query includes: `number`, `title`, `url`, `createdAt`, `isDraft`, `author`, `repository`, and `comments`
