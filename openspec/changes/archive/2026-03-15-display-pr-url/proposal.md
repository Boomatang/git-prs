## Why

When reviewing PRs in the terminal, users need quick access to the GitHub URL to open the PR in their browser. Currently, users must manually construct the URL from the org/repo#number identifier, which is error-prone and slows down the Monday morning PR review workflow.

## What Changes

- Each PR row in the table output will be followed by a second line containing the full GitHub URL
- The URL line is indented with 4 spaces to visually group it with its PR row
- This applies to both `mine` and `team` command output

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `output-formatter`: Add URL line below each PR row in table output

## Impact

- `src/formatter.zig`: Modify `formatMineRow` and `formatTeamRow` to output an additional URL line
- Output format: Each PR now takes 2 lines instead of 1
- No API changes, no breaking changes to CLI interface
