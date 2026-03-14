# git-prs

A CLI tool to view your GitHub pull requests

## Features

- **View your own open PRs** across multiple orgs (`mine` command)
- **View team member PRs** for an org (`team` command)
- **View merged PRs** - list your recently merged PRs (`merged` command)
- **Date filtering** - filter PRs by date range with `--since` and `--until`
- **Named teams** - define named teams that can span multiple organizations
- **Display PR URLs** for easy browser access
- **Draft PR styling** - draft PRs displayed with dim/italic styling for easy identification
- **Adaptive display** - terminal width detection with inline URLs when space allows
- **Case-insensitive org filtering** - match orgs regardless of capitalization
- **JSON output for scripting** - use `--json` flag for machine-readable output
- **Age and comment tracking** - see how old each PR is and comment counts

## Prerequisites

- **Zig 0.15.2 or later** - Required to build the project
- **GitHub CLI (`gh`)** - Must be installed and authenticated
  - Install: See [GitHub CLI installation guide](https://cli.github.com/manual/installation)
  - Authenticate: Run `gh auth login`
- **Config file** - Create at `~/.config/git-prs/config.json`

## Installation

```bash
git clone https://github.com/Boomatang/git-prs.git
cd git-prs
zig build
# Binary is at ./zig-out/bin/git_prs
```

## Quick Start

1. Create a minimal configuration file at `~/.config/git-prs/config.json`:

```json
{
  "mine": {
    "orgs": ["your-org"]
  }
}
```

2. Run your first command:

```bash
./zig-out/bin/git_prs mine
```

This will display all your open pull requests across the configured organizations.

## Documentation

- [CLI Reference](docs/cli-reference.md) - Detailed command-line usage and options
- [Configuration Guide](docs/config-guide.md) - Complete configuration file documentation

## License

See LICENSE file for details.
