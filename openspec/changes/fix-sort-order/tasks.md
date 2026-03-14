## 1. Update Sort Functions

- [x] 1.1 Update `sortByAge` to use `>` instead of `<` for timestamp comparison
- [x] 1.2 Update comment from "oldest first" to "newest first"
- [x] 1.3 Update `sortByAuthorThenAge` to use `>` instead of `<` for timestamp comparison within author groups

## 2. Update Tests

- [x] 2.1 Update `sortByAge` test expected order to descending (1500, 1000, 500)
- [x] 2.2 Update `sortByAuthorThenAge` test expected order within bob's PRs (1000, 800)

## 3. Verify

- [x] 3.1 Run `zig build test` to verify all tests pass
