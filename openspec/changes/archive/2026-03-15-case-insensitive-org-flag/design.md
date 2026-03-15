## Context

The `--org` flag is used in two places:
1. `mine` command: filters which orgs to fetch PRs from (in `github.zig:fetchUserPRs`)
2. `team` command: selects which team config to use (in `main.zig`)

Both currently use exact string matching (`std.mem.eql`). GitHub org names are case-insensitive at the API level, so "Kubernetes" and "kubernetes" refer to the same org.

## Goals / Non-Goals

**Goals:**
- Case-insensitive matching of `--org` value against configured org names
- Preserve original casing from config for API calls and display
- Work consistently for both `mine` and `team` commands

**Non-Goals:**
- Changing how org names are stored in config
- Normalizing org names at config load time
- Supporting partial/fuzzy matching

## Decisions

### 1. Use ASCII case-insensitive comparison

**Decision**: Use `std.ascii.eqlIgnoreCase` for comparing org names.

**Rationale**:
- GitHub org names are ASCII-only (alphanumeric and hyphens)
- Zig's standard library provides `std.ascii.eqlIgnoreCase`
- No need for full Unicode case folding

**Alternative considered**: Converting to lowercase before comparison. Rejected because it requires allocating new strings or modifying existing ones.

### 2. Compare at filter points, not storage

**Decision**: Keep org names as-is in config and args; only apply case-insensitive comparison when filtering/matching.

**Rationale**:
- Preserves original casing for error messages and API calls
- Minimal code changes - just change comparison function
- No risk of case normalization causing unexpected behavior

### 3. Match first case-insensitive hit for team lookup

**Decision**: When looking up team config, iterate and find first case-insensitive match.

**Rationale**:
- HashMap doesn't support case-insensitive keys natively
- Config shouldn't have duplicate orgs with different casing (that would be user error)
- Simple iteration over typically small team list (1-5 entries)

## Risks / Trade-offs

**[Risk]** Config has "Kubernetes" and "kubernetes" as separate entries
→ First match wins; this is a pathological config that shouldn't exist

**[Risk]** Performance of linear scan for team lookup
→ Negligible - team configs are tiny (typically 1-3 orgs)
