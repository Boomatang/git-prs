## 1. Update Mine Command Org Filtering

- [x] 1.1 Change `fetchUserPRs` in `src/github.zig` to use `std.ascii.eqlIgnoreCase` instead of `std.mem.eql` for org filter comparison

## 2. Update Team Command Org Lookup

- [x] 2.1 Create helper function in `src/main.zig` to find team config key case-insensitively
- [x] 2.2 Update team command to use case-insensitive lookup for `cfg.teams.contains`
- [x] 2.3 Update team command to use case-insensitive lookup for `cfg.teams.get`

## 3. Add Tests

- [x] 3.1 Add test in `src/github.zig` for case-insensitive org filter matching
- [x] 3.2 Add integration test for team command with different casing

## 4. Verification

- [x] 4.1 Run `zig build test` to verify all tests pass
- [x] 4.2 Manual test: `git-prs mine --org <ORG>` with different casings
- [x] 4.3 Manual test: `git-prs team --org <ORG>` with different casings
