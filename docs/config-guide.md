# git-prs Configuration Guide

## Overview

`git-prs` requires a configuration file to specify which GitHub organizations to monitor for your pull requests and optionally define team members for each organization. This guide covers how to set up and customize your configuration.

## Config File Location

The configuration file is located at:

```
~/.config/git-prs/config.json
```

Or if you have `XDG_CONFIG_HOME` set:

```
$XDG_CONFIG_HOME/git-prs/config.json
```

You'll need to create this file manually the first time you use `git-prs`.

## Minimal Configuration Example

The simplest configuration requires only specifying which organizations you want to monitor:

```json
{
  "mine": {
    "orgs": ["your-org"]
  }
}
```

This configuration will check for pull requests you've authored in the `your-org` organization.

## Full Configuration Example

Here's a complete example showing all available options:

```json
{
  "mine": {
    "orgs": ["org1", "org2", "org3"]
  },
  "teams": {
    "platform-team": {
      "members": ["alice", "bob", "charlie"],
      "orgs": ["org1", "org2"],
      "default": true
    },
    "frontend-team": {
      "members": ["dave", "eve"],
      "orgs": ["org1"]
    }
  }
}
```

This configuration:
- Monitors three organizations: `org1`, `org2`, and `org3`
- Defines two named teams with explicit membership
- The `platform-team` spans multiple organizations and is set as the default
- Allows tracking of team pull requests in addition to your own

## Configuration Field Reference

### `mine.orgs` (required)

An array of GitHub organization names to check for your pull requests.

- **Type**: Array of strings
- **Required**: Yes
- **Constraints**:
  - Must contain at least one organization
  - Organization names cannot be empty strings
  - Each organization name should be a valid GitHub organization

**Example**:
```json
{
  "mine": {
    "orgs": ["kubernetes", "my-company", "open-source-project"]
  }
}
```

### `team` (optional, legacy)

An object mapping organization names to arrays of team member GitHub usernames. When defined, `git-prs` will show pull requests from these team members in addition to your own.

**Note**: This is the legacy configuration format. For new configurations, use the `teams` object (described below) which provides more flexibility and multi-organization support.

- **Type**: Object with string keys and array values
- **Required**: No
- **Constraints**:
  - Each array must contain at least one username
  - Usernames should be valid GitHub usernames
  - Organization keys should match those in `mine.orgs`

**Example**:
```json
{
  "team": {
    "my-company": ["alice", "bob", "charlie"],
    "another-org": ["dave", "eve"]
  }
}
```

### `teams` (optional)

An object defining named teams with explicit membership and optional settings. This is the recommended way to configure teams, especially for teams that span multiple organizations.

- **Type**: Object with team names as keys
- **Required**: No

Each team object can have:
- `members`: Array of GitHub usernames (required)
- `orgs`: Array of organization names to search (required)
- `default`: Boolean, if true this team is used when no team name is specified (optional)

**Example**:
```json
{
  "teams": {
    "platform": {
      "members": ["alice", "bob"],
      "orgs": ["kubernetes", "my-company"],
      "default": true
    },
    "frontend": {
      "members": ["charlie", "dave"],
      "orgs": ["my-company"]
    }
  }
}
```

#### Multi-Organization Team Support

Unlike the legacy `team` configuration which requires separate team definitions per organization, named teams can search across multiple organizations at once. This is particularly useful when your team contributes to repositories across different GitHub organizations.

For example, a platform team that works on both internal company repos and upstream Kubernetes can be configured as:

```json
{
  "teams": {
    "platform": {
      "members": ["alice", "bob", "charlie"],
      "orgs": ["my-company", "kubernetes", "kubernetes-sigs"],
      "default": true
    }
  }
}
```

#### Default Team Selection

Setting `"default": true` on a team makes it the default when running `git-prs team` without arguments. This is convenient when you primarily work with one team but have multiple teams configured.

```json
{
  "teams": {
    "platform": {
      "members": ["alice", "bob"],
      "orgs": ["org1", "org2"],
      "default": true
    },
    "frontend": {
      "members": ["charlie", "dave"],
      "orgs": ["org1"]
    }
  }
}
```

With this configuration, running `git-prs team` will show PRs for the `platform` team, while `git-prs team frontend` will show PRs for the `frontend` team.

## Troubleshooting

### "Config file not found"

**Error message**: `Config not found. Create ~/.config/git-prs/config.json`

**Solution**: Create the configuration file at `~/.config/git-prs/config.json`. You may need to create the directory first:

```bash
mkdir -p ~/.config/git-prs
cat > ~/.config/git-prs/config.json << 'EOF'
{
  "mine": {
    "orgs": ["your-org"]
  }
}
EOF
```

Replace `your-org` with your actual GitHub organization name.

### "mine.orgs must contain at least one org"

**Error**: This occurs when the `orgs` array is empty or missing.

**Solution**: Ensure your config includes at least one organization in the `mine.orgs` array:

```json
{
  "mine": {
    "orgs": ["at-least-one-org"]
  }
}
```

### "gh CLI not installed"

**Error message**: `gh CLI not found. Install from https://cli.github.com`

**Solution**: Install the GitHub CLI tool. Visit [https://cli.github.com](https://cli.github.com) for installation instructions, or use your package manager:

```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
sudo apt install gh

# Linux (Fedora)
sudo dnf install gh

# Linux (Arch)
sudo pacman -S github-cli
```

### "Not authenticated"

**Error message**: `Not authenticated. Run 'gh auth login' first`

**Solution**: Authenticate with GitHub using the `gh` CLI:

```bash
gh auth login
```

Follow the prompts to authenticate. You'll need to choose:
- Your preferred protocol (HTTPS or SSH)
- Whether to authenticate via browser or token

### "No team configured for org"

**Error**: This occurs when you're trying to access team data for an organization that isn't in your `team` configuration.

**Solution**: Add the organization to your `team` configuration:

```json
{
  "mine": {
    "orgs": ["org1", "org2"]
  },
  "team": {
    "org1": ["teammate1", "teammate2"],
    "org2": ["teammate3", "teammate4"]
  }
}
```

Ensure that the organization name in `team` matches exactly with the name in `mine.orgs`.

### "Team not found"

**Error**: This occurs when you specify a team name that doesn't exist in your `teams` configuration.

**Solution**: Check that the team name matches exactly (case-sensitive) with one of the keys in your `teams` configuration:

```json
{
  "teams": {
    "platform-team": {
      "members": ["alice", "bob"],
      "orgs": ["org1"]
    }
  }
}
```

Use `git-prs team platform-team` (not `git-prs team platform` or `git-prs team Platform-Team`).

### "No default team"

**Error**: This occurs when you have multiple teams configured but none are marked as default, and you run `git-prs team` without specifying a team name.

**Solution**: Either:
1. Add `"default": true` to one of your teams:
   ```json
   {
     "teams": {
       "platform": {
         "members": ["alice", "bob"],
         "orgs": ["org1"],
         "default": true
       }
     }
   }
   ```
2. Or explicitly specify the team name: `git-prs team platform`

## Additional Notes

- The configuration file must be valid JSON. Use a JSON validator if you encounter parsing errors.
- Organization and username values are case-sensitive and should match exactly as they appear on GitHub.
- Changes to the configuration file take effect the next time you run `git-prs`.
- The `team` configuration is entirely optional - you can use `git-prs` with just the `mine.orgs` configuration.
