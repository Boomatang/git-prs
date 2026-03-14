## Context

The `merged` command was added in commit 6b6587c. It uses a separate GraphQL query function `fetchMergedPRsWithGh` but shares the `parsePullRequestFromGraphQL` parser with the `mine` and `team` commands.

The parser expects these fields from each PR node:
- `number`, `title`, `url`, `createdAt`, `isDraft`, `author`, `repository`, `comments`

The `fetchMergedPRsWithGh` query at line 309-333 is missing `isDraft`, causing `parsePullRequestFromGraphQL` to return `ParseError` at line 399.

## Goals / Non-Goals

**Goals:**
- Fix the merged command so it works
- Maintain consistency with other GraphQL queries

**Non-Goals:**
- Refactoring the GraphQL query construction
- Adding tests (separate concern)

## Decisions

### 1. Add missing field to query

**Decision**: Add `isDraft` to the GraphQL query in `fetchMergedPRsWithGh`.

**Rationale**: This is the minimal fix. The field is required by the shared parser and should have been included when the query was written.

**Alternatives considered**:
- Make `isDraft` optional in parser (rejected: adds complexity, `isDraft` is useful data)
- Create separate parser for merged PRs (rejected: unnecessary duplication)

## Risks / Trade-offs

**[None significant]** - This is a one-line fix with no architectural implications.
