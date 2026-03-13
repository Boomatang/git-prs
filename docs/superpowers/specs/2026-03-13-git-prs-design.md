# git-prs Design Specification

## Overview

`git-prs` is a CLI tool for developers to review their open pull requests across multiple GitHub organizations. It serves two primary use cases:

1. **Personal review**: Check the status of all your open PRs across multiple orgs
2. **Team lead review**: Check what PRs your team members have open in a specific org

The tool is designed for a "Monday morning" workflow — quickly scanning PR health to identify what needs attention.

## Goals

- Fast PR status overview across multiple GitHub orgs
- Show engagement signals: PR age, number of commenters, time since last comment
- Simple configuration, minimal dependencies
- Leverage existing `gh` CLI authentication

## Non-Goals

- Watch/daemon mode with notifications (explicitly out of scope, permanently)
- CI status or review approval tracking
- Bulk open functionality (maybe later, not in initial scope)

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│   CLI       │────▶│   Config    │────▶│   GitHub Client     │
│   Parser    │     │   Loader    │     │   (std.http)        │
└─────────────┘     └─────────────┘     └──────────┬──────────┘
      │                   │                        │
      │                   ▼                        ▼
      │             ┌─────────────┐         ┌─────────────┐
      │             │  gh auth    │         │  GitHub     │
      │             │  token      │         │  GraphQL    │
      │             └─────────────┘         └─────────────┘
      │                                            │
      ▼                                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Output Formatter                        │
│                  (compact table to stdout)                   │
└─────────────────────────────────────────────────────────────┘
```

### Components

| Component | Responsibility |
|-----------|----------------|
| CLI Parser | Parse commands and flags |
| Config Loader | Read XDG config file, validate JSON |
| GitHub Client | HTTP calls to GitHub GraphQL API |
| Output Formatter | Render PR data as compact table |

### Component Interfaces

**CLI Parser → Config Loader:**
```zig
const Command = union(enum) {
    mine: MineArgs,
    team: TeamArgs,
};

const MineArgs = struct {
    org_filter: ?[]const u8,  // --org value or null
    limit: u32,               // --limit value, default 50
};

const TeamArgs = struct {
    org: []const u8,          // --org value (required)
    member_filter: ?[]const u8,  // --member value or null
};
```

**Config Loader → GitHub Client:**
```zig
const Config = struct {
    mine_orgs: [][]const u8,           // orgs to check for personal PRs
    team_members: std.StringHashMap([][]const u8),  // org -> member list
    auth_token: []const u8,            // from gh auth token
    authenticated_user: []const u8,    // from GitHub API /user
};
```

**GitHub Client → Output Formatter:**
```zig
const PullRequest = struct {
    org: []const u8,
    repo: []const u8,
    number: u32,
    title: []const u8,
    url: []const u8,
    author: []const u8,
    created_at: i64,          // unix timestamp
    last_comment_at: ?i64,    // null if no comments
    unique_commenters: u32,
};
```

### Technology Choices

- **Language**: Zig 0.15.2
- **HTTP**: `std.http` (standard library)
- **JSON parsing**: `std.json` (standard library)
- **Authentication**: Shell out to `gh auth token`
- **GitHub API**: GraphQL (fewer round trips than REST)
- **External dependencies**: None

## CLI Interface

### Commands

```
git-prs mine [OPTIONS]
  --org <name>               # Filter to specific org (optional)
  --limit <n>                # Max PRs to show (default: 50)

git-prs team [OPTIONS]
  --org <name>               # Which org to check (required if multiple configured)
  --member <username>        # Filter to specific team member (optional)
```

### Examples

```bash
# All your PRs across all configured orgs
git-prs mine

# Your PRs in a specific org
git-prs mine --org kubernetes

# Your team's PRs in an org
git-prs team --org my-company

# Specific team member's PRs
git-prs team --org my-company --member alice
```

## Configuration

### Location

`~/.config/git-prs/config.json` (XDG config directory)

### Format

```json
{
  "mine": {
    "orgs": ["jfitzpat", "kubernetes", "my-company"]
  },
  "team": {
    "my-company": ["alice", "bob", "charlie"],
    "other-org": ["dave", "eve"]
  }
}
```

### Fields

- `mine.orgs`: List of GitHub orgs/usernames to check for your PRs. Include your own username to check personal repos.
- `team.<org>`: List of team member usernames for each org you lead.

### Authentication

No auth configuration in git-prs. Token is obtained by running `gh auth token`, which returns the token from the user's existing `gh` CLI authentication.

The authenticated user's GitHub username is obtained by calling the GitHub API `/user` endpoint with the token. This is cached for the duration of the command.

### Config Validation

| Rule | Error Message |
|------|---------------|
| `mine.orgs` missing or empty | "Config error: mine.orgs must contain at least one org" |
| `mine.orgs` contains empty string | "Config error: mine.orgs contains empty org name" |
| `team.<org>` is empty array | "Config error: team.{org} has no members listed" |
| Org name contains invalid chars | No validation; GitHub API will reject invalid orgs |
| `team` section missing | Allowed; `git-prs team` will error with "No teams configured" |

## Output Format

### Personal view (`git-prs mine`)

```
ORG/REPO#NUM   TITLE                          AGE    👤    LAST
─────────────────────────────────────────────────────────────────
k8s/kube#1234  Fix node scheduling bug...     3d     4     2h
my-co/api#567  Add retry logic to client...   1w     2     3d
my-co/web#89   Update dashboard styles...     2d     1     2d
```

### Team view (`git-prs team`)

```
AUTHOR   ORG/REPO#NUM      TITLE                      AGE    👤    LAST
────────────────────────────────────────────────────────────────────────
alice    my-co/api#567     Add retry logic...         1w     2     3d
alice    my-co/api#590     Fix timeout handling...    2d     3     1h
bob      my-co/web#89      Update dashboard...        2d     1     2d
charlie  my-co/core#234    Refactor auth module...    5d     0     5d
```

### Columns

| Column | Description |
|--------|-------------|
| AUTHOR | PR author username (team view only) |
| ORG/REPO#NUM | PR identifier, formatted as clickable URL for terminals that support it |
| TITLE | PR title, truncated to fit terminal width |
| AGE | Time since PR was opened |
| 👤 | Number of different people who have commented |
| LAST | Time since most recent comment (shows "-" if no comments) |

### Output Formatting Details

**Terminal width detection:**
- Use `COLUMNS` environment variable if set
- Otherwise default to 80 columns
- No terminal ioctl queries (keeps it simple)

**Title truncation:**
- Fixed column widths: AUTHOR (8), ORG/REPO#NUM (20), AGE (5), 👤 (3), LAST (5)
- TITLE gets remaining width minus spacing
- Truncation adds "..." at end if title exceeds available width

**Time formatting:**
| Duration | Format |
|----------|--------|
| < 1 hour | "Xm" (e.g., "45m") |
| 1-23 hours | "Xh" (e.g., "3h") |
| 1-6 days | "Xd" (e.g., "3d") |
| 1-4 weeks | "Xw" (e.g., "2w") |
| > 4 weeks | "Xmo" (e.g., "2mo") |

**Sort order:**
- Default sort by AGE descending (oldest PRs first — they need attention)
- Team view: secondary sort by AUTHOR (group same author together)

**URL formatting:**
- Print full GitHub URL (e.g., `https://github.com/org/repo/pull/123`)
- Kitty and other modern terminals auto-detect URLs

## Error Handling

| Scenario | Behavior |
|----------|----------|
| `gh` not installed | Error: "gh CLI not found. Install from https://cli.github.com" |
| `gh auth token` fails | Error: "Not authenticated. Run `gh auth login` first" |
| Config file missing | Error: "Config not found. Create ~/.config/git-prs/config.json" with example |
| Config file invalid JSON | Error: "Invalid config: {parse error details}" |
| `git-prs team` without --org (multiple teams configured) | Error: "Multiple teams configured. Specify --org: my-company, other-org" |
| `git-prs team --org X` where X not in config | Error: "No team configured for org 'X'" |
| No teams configured | Error: "No teams configured in config file" |
| Org not accessible | Warning per org, continue with others: "Warning: kubernetes: not authorized, skipping" |
| Network failure | Error: "Failed to reach GitHub API: {details}" |
| No PRs found | Message: "No open PRs found" (exit 0, not an error) |

### Principles

- **Fail fast** on setup issues (missing gh, no auth, bad config)
- **Be resilient** on per-org issues (skip inaccessible orgs with warning, show what we can)

## Data Requirements

### GitHub GraphQL Query

Use GitHub's GraphQL API to search for open PRs. Query structure:

```graphql
query($query: String!, $first: Int!, $after: String) {
  search(query: $query, type: ISSUE, first: $first, after: $after) {
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes {
      ... on PullRequest {
        number
        title
        url
        createdAt
        author { login }
        comments(first: 100) {
          nodes {
            author { login }
            createdAt
          }
        }
      }
    }
  }
}
```

**Query string construction:**
- For `mine`: `is:pr is:open author:@me org:{org}`
- For `team`: `is:pr is:open author:{member} org:{org}` (one query per member)

### Pagination

- Fetch up to `--limit` PRs (default 50)
- Use cursor-based pagination (`after` parameter)
- Page size: 50 items per request
- If `--limit` exceeds results, stop when no more pages

### Derived Fields

| Field | Calculation |
|-------|-------------|
| AGE | `now - created_at` |
| 👤 (commenters) | Count of unique `author.login` values in comments (excluding PR author) |
| LAST | `now - most_recent_comment.createdAt` (null if no comments, display as "-") |

## Future Considerations

These are explicitly not in scope for initial implementation but noted for potential future work:

- **Bulk open**: `git-prs open <pattern>` to open multiple PRs in browser
- **Filtering**: `--stale` flag to show only PRs with no recent activity
- **Sorting**: Options to sort by age, activity, etc.
