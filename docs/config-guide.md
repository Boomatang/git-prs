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
  "team": {
    "org1": ["alice", "bob", "charlie"],
    "org2": ["dave", "eve"],
    "org3": ["frank", "grace", "henry"]
  }
}
```

This configuration:
- Monitors three organizations: `org1`, `org2`, and `org3`
- Defines team members for each organization
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

### `team` (optional)

An object mapping organization names to arrays of team member GitHub usernames. When defined, `git-prs` will show pull requests from these team members in addition to your own.

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

## Additional Notes

- The configuration file must be valid JSON. Use a JSON validator if you encounter parsing errors.
- Organization and username values are case-sensitive and should match exactly as they appear on GitHub.
- Changes to the configuration file take effect the next time you run `git-prs`.
- The `team` configuration is entirely optional - you can use `git-prs` with just the `mine.orgs` configuration.
