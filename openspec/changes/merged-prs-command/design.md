## Context

The application currently supports `mine` and `team` commands for listing open PRs. Both use GraphQL queries with `is:open` state filter. The `mine` command already supports `--since` and `--until` flags for filtering by creation date.

For merged PRs, the GitHub search API uses different query syntax:
- State: `is:merged` instead of `is:open`
- Date filter: `merged:>=DATE` instead of `created:>=DATE`

The existing `PullRequest` struct and JSON output format can be reused, though merged PRs don't need comment-related fields (commenters, last_comment_at) for the reporting use case.

## Goals / Non-Goals

**Goals:**
- Enable quick extraction of merged PR URLs for weekly reporting
- Provide sensible defaults (7 days) while allowing customization
- Maintain consistency with existing command patterns (`--org`, `--json`)
- Keep output copy-paste friendly for document insertion

**Non-Goals:**
- Team-level merged PR reporting (can be added later)
- Configurable default window in config file (7 days is sufficient)
- Rich table output like `mine` command (URLs are the primary need)

## Decisions

### 1. Compute dates at runtime for `--days` flag

**Choice:** Calculate the since date by subtracting N days from the current date at command execution time.

**Alternatives considered:**
- Store relative dates in config: Adds complexity, 7-day default is sufficient
- Require explicit dates always: Poor UX for the common weekly use case

**Rationale:** Simple implementation, intuitive behavior. `--days 7` means "last 7 days from now".

### 2. Mutual exclusion between `--days` and `--since`/`--until`

**Choice:** Return an error if `--days` is combined with `--since` or `--until`.

**Alternatives considered:**
- Let `--since`/`--until` override `--days`: Silently ignoring flags is confusing
- Allow `--days` with `--until` (window ending on specific date): Adds complexity for rare use case

**Rationale:** Clear behavior. Use `--days` for relative windows, use `--since`/`--until` for explicit ranges. No ambiguity.

### 3. Plain URL output as default format

**Choice:** Output one URL per line with no additional formatting.

**Alternatives considered:**
- Table format like `mine`: Overkill for copy-paste use case
- Markdown list format: Extra characters to remove when pasting

**Rationale:** Optimized for the stated use case of pasting URLs into a Google Doc. No transformation needed.

### 4. Reuse PullRequest struct for JSON output

**Choice:** Return full PR objects in JSON mode, consistent with `mine --json`.

**Alternatives considered:**
- Return array of URL strings only: Inconsistent with other commands
- Create separate MergedPR struct: Unnecessary complexity

**Rationale:** Consistency with existing commands. Consumers can extract the fields they need.

## Risks / Trade-offs

**[Risk] GraphQL query differences for merged PRs** → The `merged:>=DATE` syntax is well-documented. Test with real GitHub API during implementation.

**[Trade-off] No comment data for merged PRs** → Comment fields will be fetched but may not be meaningful post-merge. Acceptable since JSON consumers can ignore unused fields.

**[Trade-off] Plain output not suitable for all use cases** → Users needing structured data can use `--json`. The default optimizes for the primary use case.
