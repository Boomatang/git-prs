# Add --open Flag

## Problem

Currently, opening PR URLs in a browser requires piping through external tools:

```sh
git_prs team --json | yq ".[].url" | xargs -I {} xdg-open {}
```

This is clunky for a common workflow: quickly reviewing team PRs by opening them all in browser tabs.

## Solution

Add an `--open` flag to all PR-listing commands (`mine`, `team`, `merged`) that opens matching PR URLs directly in the default browser.

```sh
git_prs team --open
git_prs mine --open --org kubernetes
git_prs merged --open --days 7
```

## Behavior

- Opens all matching PR URLs in the default browser
- Prints feedback: "Opening N PRs..." or "No PRs to open"
- Suppresses normal table output when used
- Mutually exclusive with `--json` (error if both specified)

## Platform Support

| Platform | Opener Command |
|----------|----------------|
| Linux    | `xdg-open`     |
| macOS    | `open`         |
| Windows  | Not supported (compile error) |

## Scope

- Applies to: `mine`, `team`, `merged` commands
- No confirmation prompt (user knows what they asked for)
- Works with all existing filters (`--org`, `--member`, `--since`, etc.)

## Non-Goals

- No `--open` for `help` or `version` commands
- No interactive selection of which PRs to open
- No Windows support in this change
