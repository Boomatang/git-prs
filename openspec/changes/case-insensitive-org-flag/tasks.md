## 1. Update Mine Command Org Filtering

- [ ] 1.1 Change `fetchUserPRs` in `src/github.zig` to use `std.ascii.eqlIgnoreCase` instead of `std.mem.eql` for org filter comparison

## 2. Update Team Command Org Lookup

- [ ] 2.1 Create helper function in `src/main.zig` to find team config key case-insensitively
- [ ] 2.2 Update team command to use case-insensitive lookup for `cfg.teams.contains`
- [ ] 2.3 Update team command to use case-insensitive lookup for `cfg.teams.get`

## 3. Add Tests

- [ ] 3.1 Add test in `src/github.zig` for case-insensitive org filter matching
- [ ] 3.2 Add integration test for team command with different casing

## 4. Verification

- [ ] 4.1 Run `zig build test` to verify all tests pass
- [ ] 4.2 Manual test: `git-prs mine --org <ORG>` with different casings
- [ ] 4.3 Manual test: `git-prs team --org <ORG>` with different casings
