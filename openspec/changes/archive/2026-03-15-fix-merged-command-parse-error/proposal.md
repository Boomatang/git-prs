## Why

The `merged` command fails with "Failed to parse GitHub API response" for all users. The GraphQL query in `fetchMergedPRsWithGh` is missing the `isDraft` field, but the shared `parsePullRequestFromGraphQL` function requires it. This makes the entire `merged` command unusable.

## What Changes

- Add `isDraft` field to the GraphQL query in `fetchMergedPRsWithGh` function at `src/github.zig:317`

## Capabilities

### New Capabilities

None - this is a bug fix.

### Modified Capabilities

- `github-client`: The merged PRs GraphQL query must include all fields required by the shared parser

## Impact

- `src/github.zig` - Add missing `isDraft` field to merged PRs GraphQL query (line ~317)
