## Context

Currently, teams are defined in `config.json` as a simple mapping of org name to array of member usernames:

```json
"team": {
  "my-company": ["alice", "bob", "charlie"]
}
```

When running `git-prs team --org my-company`, all open PRs from those members are fetched regardless of when they were created. This becomes problematic when:
- A team forms mid-project and wants to track only PRs from that point forward
- A team disbands and some members join new teams
- Members transition between teams at different times

The GitHub GraphQL search API supports date filtering via `created:>=YYYY-MM-DD` and `created:<=YYYY-MM-DD` syntax in the search query.

## Goals / Non-Goals

**Goals:**
- Allow teams to define optional date ranges (`since`, `until`) in configuration
- Allow CLI flags to override or specify date ranges for both `team` and `mine` commands
- Filter PRs server-side for efficiency using GitHub's search query syntax
- Support open-ended ranges (only `since`, only `until`, or both)

**Non-Goals:**
- Backwards compatibility with old config format (breaking change accepted)
- Date filtering based on PR update time or merge time (only creation date)
- Complex date expressions (relative dates like "30 days ago")

## Decisions

### 1. Config format change: Array to Object

**Decision**: Change team value from array to object with `members`, `since`, `until` fields.

**New format**:
```json
"team": {
  "current-team": {
    "members": ["alice", "bob"],
    "since": "2025-01-15"
  },
  "old-team": {
    "members": ["alice", "charlie"],
    "since": "2024-01-01",
    "until": "2024-12-31"
  }
}
```

**Rationale**: An object structure allows for future extensibility (adding more team metadata) and clearly separates the member list from filtering options.

**Alternative considered**: Nested structure under each org. Rejected because it adds unnecessary complexity for a simple feature.

### 2. Date format: ISO 8601 date (YYYY-MM-DD)

**Decision**: Use `YYYY-MM-DD` format for all date inputs.

**Rationale**:
- Unambiguous and internationally recognized
- Matches GitHub's date format in API responses
- Easy to parse and validate

**Alternative considered**: Unix timestamps. Rejected because they're not human-readable in config files.

### 3. Server-side filtering via GitHub search query

**Decision**: Append `created:>=YYYY-MM-DD` and `created:<=YYYY-MM-DD` to the existing search query.

**Current query**:
```
is:pr is:open author:alice org:my-company
```

**New query with dates**:
```
is:pr is:open author:alice org:my-company created:>=2025-01-15 created:<=2025-12-31
```

**Rationale**:
- Reduces data transfer from GitHub
- Leverages GitHub's optimized search infrastructure
- No post-fetch filtering required

**Alternative considered**: Client-side filtering after fetching all PRs. Rejected because it fetches unnecessary data and wastes API quota.

### 4. CLI override behavior

**Decision**: CLI flags (`--since`, `--until`) always override config values when specified.

**Priority order**:
1. CLI flag (if provided)
2. Config value (if defined)
3. No filter (default - all dates)

**Rationale**: Allows one-off queries with different date ranges without modifying config.

### 5. Date boundaries are inclusive

**Decision**: Both `since` and `until` dates are inclusive boundaries.

**Rationale**: Matches intuitive expectations - "since 2025-01-15" includes PRs created on that day.

## Risks / Trade-offs

**[Breaking config change]** → Users must update their config files. Mitigation: Clear error message explaining the new format with an example.

**[Date parsing errors]** → Invalid date formats could cause runtime errors. Mitigation: Validate date format during config parsing and CLI parsing, fail early with clear error message.

**[Timezone ambiguity]** → YYYY-MM-DD doesn't include timezone. Mitigation: GitHub interprets dates in UTC, document this behavior.
