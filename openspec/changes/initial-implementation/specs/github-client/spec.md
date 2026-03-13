## ADDED Requirements

### Requirement: Fetch user PRs via GraphQL
The GitHub client SHALL fetch open PRs authored by the authenticated user using the GraphQL API.

#### Scenario: Fetch PRs for single org
- **WHEN** client queries for user's PRs in org "kubernetes"
- **THEN** client sends GraphQL search query with `is:pr is:open author:@me org:kubernetes`

#### Scenario: Fetch PRs with pagination
- **WHEN** results exceed page size (50) and limit allows more
- **THEN** client fetches additional pages using cursor-based pagination

#### Scenario: Respect limit parameter
- **WHEN** limit is set to 10 and org has 50 PRs
- **THEN** client returns only 10 PRs

### Requirement: Fetch team member PRs via GraphQL
The GitHub client SHALL fetch open PRs authored by specified team members.

#### Scenario: Fetch PRs for team member
- **WHEN** client queries for PRs by user "alice" in org "my-company"
- **THEN** client sends GraphQL search query with `is:pr is:open author:alice org:my-company`

#### Scenario: Fetch PRs for multiple team members
- **WHEN** client queries for team with members ["alice", "bob"]
- **THEN** client sends separate queries for each member and combines results

### Requirement: Extract PR metadata
The GitHub client SHALL extract required fields from GraphQL response.

#### Scenario: Parse PR fields
- **WHEN** GraphQL response contains PR data
- **THEN** client extracts: number, title, url, createdAt, author.login, repository.owner.login, repository.name

#### Scenario: Compute unique commenters
- **WHEN** PR has comments from multiple users
- **THEN** client counts unique author.login values excluding the PR author

#### Scenario: Handle PR with no comments
- **WHEN** PR has no comments
- **THEN** client sets unique_commenters=0 and last_comment_at=null

#### Scenario: Determine last comment time
- **WHEN** PR has comments
- **THEN** client extracts createdAt from the most recent comment

### Requirement: Handle API errors gracefully
The GitHub client SHALL handle API errors without crashing.

#### Scenario: Org not accessible
- **WHEN** API returns authorization error for an org
- **THEN** client logs warning "Warning: {org}: not authorized, skipping" to stderr and continues with other orgs

#### Scenario: Network failure
- **WHEN** API request fails due to network error
- **THEN** client exits with error "Failed to reach GitHub API: {details}"

#### Scenario: Rate limit exceeded
- **WHEN** API returns rate limit error
- **THEN** client exits with error "GitHub API rate limit exceeded. Try again later."
