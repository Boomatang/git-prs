# git-prs CLI Reference

## Overview

`git-prs` is a command-line tool for managing GitHub Pull Requests. It allows you to view your own PRs and your team's PRs across multiple organizations with configurable filtering options. The tool integrates with GitHub CLI (`gh`) for authentication and uses your local configuration file to determine which organizations and team members to track.

## Commands

### `git-prs mine`

List pull requests assigned to you across configured organizations.

**Syntax:**
```
git-prs mine [OPTIONS]
```

**Options:**

- `--org <name>` - Filter to a specific organization (case-insensitive). When omitted, shows PRs from all configured organizations in your `mine.orgs` list.
- `--limit <n>` - Maximum number of PRs to display. Default: `50`. Must be a positive integer.
- `--json` - Output results as a JSON array instead of formatted table. Useful for scripting and piping to other tools.

**Description:**

Fetches and displays all open pull requests where you are the author from the organizations configured in your `~/.config/git-prs/config.json` file under the `mine.orgs` field.

---

### `git-prs team`

List pull requests from your team members within a specific organization.

**Syntax:**
```
git-prs team [OPTIONS]
```

**Options:**

- `--org <name>` - Specify which organization's team to query (case-insensitive). If you have only one team configured, this can be omitted and will be auto-selected. If you have multiple teams configured, this option is required.
- `--member <username>` - Filter to a specific team member's PRs. When omitted, shows PRs from all team members.
- `--json` - Output results as a JSON array instead of formatted table. Useful for scripting and piping to other tools.

**Description:**

Fetches and displays open pull requests from team members defined in your `~/.config/git-prs/config.json` file under the `team.<org>` field.

---

### `git-prs --help` / `git-prs -h`

Display usage information and help text.

**Syntax:**
```
git-prs --help
git-prs -h
```

**Description:**

Prints a summary of available commands and their options. Running `git-prs` with no arguments also displays this help message.

## Examples

### Basic Usage

View all your open PRs:
```bash
git-prs mine
```

View your team's open PRs (auto-selects org if only one team configured):
```bash
git-prs team
```

View your team's PRs for a specific organization:
```bash
git-prs team --org kubernetes
```

### Filtering by Organization

View only your PRs from the Kubernetes organization:
```bash
git-prs mine --org kubernetes
```

Case-insensitive org matching:
```bash
git-prs mine --org KUBERNETES
git-prs team --org KuBeRnEtEs
```

### Limiting Results

Show only your 10 most recent PRs:
```bash
git-prs mine --limit 10
```

Combine org filter with limit:
```bash
git-prs mine --org openshift --limit 5
```

### Viewing Specific Team Member's PRs

View only Alice's PRs:
```bash
git-prs team --org my-company --member alice
```

### JSON Output for Scripting

Get JSON output for processing with `jq`:
```bash
git-prs mine --json
```

Count your open PRs:
```bash
git-prs mine --json | jq 'length'
```

Extract PR titles from a specific org:
```bash
git-prs mine --org kubernetes --json | jq -r '.[].title'
```

Get PR URLs for team member Bob:
```bash
git-prs team --org my-company --member bob --json | jq -r '.[].url'
```

Filter PRs by status using jq:
```bash
git-prs mine --json | jq '[.[] | select(.state == "OPEN")]'
```

## Exit Codes and Error Messages

### Exit Codes

- `0` - Success: Command completed successfully
- `1` - Error: Command failed (see error message on stderr for details)

### Common Errors

#### Configuration Errors

**Error:** `Config file not found at: ~/.config/git-prs/config.json`
- **Cause:** The configuration file doesn't exist.
- **Solution:** Create `~/.config/git-prs/config.json` with your organization and team settings.

**Error:** `Invalid config: JSON parse error`
- **Cause:** The configuration file contains invalid JSON syntax.
- **Solution:** Validate your JSON using a linter or JSON validator.

**Error:** `Config error: mine.orgs must contain at least one org`
- **Cause:** The `mine.orgs` array is missing or empty.
- **Solution:** Add at least one organization to the `mine.orgs` array in your config.

**Error:** `Config error: mine.orgs contains empty org name`
- **Cause:** One of the org names in `mine.orgs` is an empty string.
- **Solution:** Remove empty strings from the `mine.orgs` array.

**Error:** `Config error: team has no members listed`
- **Cause:** A team in the `teams` object has an empty members array.
- **Solution:** Add team member usernames to the team's member list or remove the team entry.

**Error:** `No teams configured in config file`
- **Cause:** Running `git-prs team` without any teams defined in config.
- **Solution:** Add at least one team to the `teams` object in your config.

**Error:** `No team configured for org 'orgname'`
- **Cause:** Specified org doesn't exist in your `teams` configuration.
- **Solution:** Check the org name spelling or add the team to your config.

**Error:** `Multiple teams configured. Specify --org`
- **Cause:** Running `git-prs team` without `--org` when multiple teams are configured.
- **Solution:** Specify which org's team to query using `--org <name>`.

#### Authentication Errors

**Error:** `gh is not installed or not found in PATH`
- **Cause:** GitHub CLI is not installed or not accessible.
- **Solution:** Install GitHub CLI from https://cli.github.com/

**Error:** `gh auth token failed. Please run 'gh auth login' first`
- **Cause:** Not authenticated with GitHub CLI.
- **Solution:** Run `gh auth login` to authenticate.

**Error:** `Authentication failed. Your token may have expired. Run 'gh auth login'.`
- **Cause:** GitHub API rejected the authentication token.
- **Solution:** Re-authenticate using `gh auth login`.

#### GitHub API Errors

**Error:** `GitHub API rate limit exceeded. Try again later.`
- **Cause:** Exceeded GitHub API rate limit.
- **Solution:** Wait for the rate limit to reset (typically 1 hour) or authenticate with a token that has higher limits.

**Error:** `Failed to reach GitHub API. Check your network connection.`
- **Cause:** Network connectivity issue.
- **Solution:** Verify internet connection and check if GitHub is accessible.

**Error:** `Failed to parse GitHub API response.`
- **Cause:** Unexpected response format from GitHub API.
- **Solution:** This may indicate a breaking change in the GitHub API. Check for updates to `git-prs`.

**Error:** `GitHub CLI command failed.`
- **Cause:** The underlying `gh` command execution failed.
- **Solution:** Verify `gh` is working correctly by running `gh api user` manually.

#### Command Line Errors

**Error:** `Unknown command. Use 'mine' or 'team'.`
- **Cause:** Invalid command provided.
- **Solution:** Use either `mine` or `team` as the command.

**Error:** `Invalid flag.`
- **Cause:** Used an unrecognized flag.
- **Solution:** Check the available flags for your command using `--help`.

**Error:** `Missing value for flag.`
- **Cause:** Provided a flag that requires a value without supplying the value.
- **Solution:** Provide a value after the flag (e.g., `--org kubernetes` instead of just `--org`).

**Error:** `Invalid limit value. Must be a number.`
- **Cause:** The `--limit` flag was given a non-numeric value.
- **Solution:** Provide a positive integer for `--limit` (e.g., `--limit 25`).

## Configuration File

The tool expects a configuration file at `~/.config/git-prs/config.json` with the following structure:

```json
{
  "mine": {
    "orgs": ["kubernetes", "openshift"]
  },
  "team": {
    "my-company": ["alice", "bob", "charlie"],
    "kubernetes": ["contributor1", "contributor2"]
  }
}
```

- `mine.orgs`: Array of organization names where you want to track your own PRs
- `team`: Object mapping organization names to arrays of team member GitHub usernames

## Notes

- Organization names are matched case-insensitively
- Authentication is handled via GitHub CLI (`gh`) - ensure you're logged in with `gh auth login`
- Default limit is 50 PRs, but can be adjusted with `--limit`
- JSON output format is designed to be compatible with standard JSON processing tools like `jq`
- The tool only shows open pull requests (not closed or merged PRs)
