## Context

Current config structure is org-centric:

```json
{
  "team": {
    "my-org": {
      "members": ["alice", "bob"],
      "since": "2025-01-01"
    }
  }
}
```

This doesn't support teams that span multiple orgs. A "release" team might have members across org-a and org-b, but the current structure forces one team definition per org.

## Goals / Non-Goals

**Goals:**
- Named teams that can span multiple GitHub orgs
- Explicit org list per team (no inheritance/magic)
- Default team for bare `git_prs team` command
- Single-team auto-selection when only one team defined
- Clear validation errors for misconfiguration

**Non-Goals:**
- Backward compatibility with old `"team"` format (breaking change accepted)
- Org inheritance from `mine.orgs` (explicit orgs required)
- Migration tooling (product in early stages)

## Decisions

### Decision 1: New `teams` config key with named teams

```json
{
  "teams": {
    "default": "release",
    "release": {
      "orgs": ["org-a", "org-b"],
      "members": ["alice", "bob", "carol"],
      "since": "2025-01-01"
    },
    "traffic": {
      "orgs": ["org-a", "org-c"],
      "members": ["dave", "eve"]
    }
  }
}
```

**Rationale**: Clean break from org-centric to team-centric model. The `default` key is a reserved name that points to another team.

**Alternative considered**: Keep `team` key and add nesting - rejected because it complicates parsing and the old structure fundamentally doesn't fit.

### Decision 2: Require explicit orgs per team

Each team MUST specify its `orgs` array. No inheritance from `mine.orgs`.

**Rationale**: Explicit is better than implicit. Teams searching different org sets is the core use case.

**Alternative considered**: Optional orgs that defaults to `mine.orgs` - rejected because it adds ambiguity and magic behavior.

### Decision 3: Single team auto-selection

When only one team is defined and no `default` is set, that team is used automatically.

```json
{
  "teams": {
    "release": { "orgs": [...], "members": [...] }
  }
}
```

`git_prs team` → uses "release" automatically.

**Rationale**: Reduces config boilerplate for simple cases.

### Decision 4: Multiple teams require default or explicit name

When multiple teams exist:
- If `default` is set: `git_prs team` uses it
- If `default` not set: `git_prs team` errors, must use `git_prs team <name>`

**Rationale**: Fail fast rather than guess which team the user wants.

### Decision 5: New TeamConfig struct

```zig
pub const NamedTeamConfig = struct {
    orgs: []const []const u8,
    members: []const []const u8,
    since: ?[]const u8 = null,
    until: ?[]const u8 = null,
};

pub const TeamsConfig = struct {
    default: ?[]const u8,
    teams: std.StringHashMapUnmanaged(NamedTeamConfig),
};
```

**Rationale**: Separates the default pointer from team definitions. Clean ownership model.

### Decision 6: CLI argument for team name

```
git_prs team [name]
```

Positional argument after `team` subcommand. If provided, uses that team. If not, uses default/single-team logic.

**Rationale**: Simple, follows common CLI patterns.

## Risks / Trade-offs

**[Risk]** Breaking change for existing users → Mitigation: Accepted; product in early stages, clear error on old config.

**[Trade-off]** Must duplicate orgs if team searches same orgs as `mine` → Acceptable; explicit > implicit.

**[Trade-off]** Reserved `default` key can't be a team name → Acceptable; unlikely anyone wants a team named "default".
