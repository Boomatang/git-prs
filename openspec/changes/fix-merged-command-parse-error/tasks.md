## 1. Fix GraphQL Query

- [ ] 1.1 Add `isDraft` field to GraphQL query in `fetchMergedPRsWithGh` at src/github.zig:317

## 2. Verify Fix

- [ ] 2.1 Build the project with `zig build`
- [ ] 2.2 Run `git-prs merged` and verify it no longer returns parse error
- [ ] 2.3 Run `git-prs merged --days 100` and verify extended date range works
