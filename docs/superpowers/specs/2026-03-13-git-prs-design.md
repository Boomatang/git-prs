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
| LAST | Time since most recent comment |

## Error Handling

| Scenario | Behavior |
|----------|----------|
| `gh` not installed | Error: "gh CLI not found. Install from https://cli.github.com" |
| `gh auth token` fails | Error: "Not authenticated. Run `gh auth login` first" |
| Config file missing | Error: "Config not found. Create ~/.config/git-prs/config.json" with example |
| Config file invalid JSON | Error: "Invalid config: {parse error details}" |
| Org not accessible | Warning per org, continue with others: "Warning: kubernetes: not authorized, skipping" |
| Network failure | Error: "Failed to reach GitHub API: {details}" |
| No PRs found | Message: "No open PRs found" (exit 0, not an error) |

### Principles

- **Fail fast** on setup issues (missing gh, no auth, bad config)
- **Be resilient** on per-org issues (skip inaccessible orgs with warning, show what we can)

## Data Requirements

### GitHub GraphQL Query

For each org, fetch open PRs with:
- PR number, title, URL
- Author username
- Created timestamp
- Updated timestamp
- Comments: count of unique commenters, timestamp of most recent comment

### Derived Fields

| Field | Calculation |
|-------|-------------|
| AGE | `now - created_at` |
| 👤 (commenters) | Count of unique usernames in comments |
| LAST | `now - most_recent_comment_at` |

## Future Considerations

These are explicitly not in scope for initial implementation but noted for potential future work:

- **Bulk open**: `git-prs open <pattern>` to open multiple PRs in browser
- **Filtering**: `--stale` flag to show only PRs with no recent activity
- **Sorting**: Options to sort by age, activity, etc.
