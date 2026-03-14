## Context

The current output uses formatted tables with headers, separators, and padded columns. This is optimized for human readability but cannot be easily consumed by scripts or piped to tools like `jq`.

The `PullRequest` struct already contains all fields needed for JSON output. Zig's standard library provides `std.json.stringify` for serialization.

## Goals / Non-Goals

**Goals:**
- Machine-readable JSON output when `--json` flag is specified
- Include all PR fields in JSON output
- Output valid JSON that can be piped to `jq` and other tools
- Maintain backward compatibility - table output remains default

**Non-Goals:**
- Pretty-printing JSON (output is compact single-line)
- Filtering which fields to include (all fields always included)
- Streaming output (entire array is serialized at once)
- JSONL (newline-delimited JSON) format

## Decisions

### 1. Use Zig's std.json for serialization

**Decision**: Use `std.json.stringify` from the standard library.

**Rationale**:
- Built-in, no external dependencies
- Handles escaping and formatting correctly
- Works with Zig structs directly

**Alternative considered**: Manual JSON string building. Rejected because it's error-prone and duplicates what std.json provides.

### 2. Output as JSON array

**Decision**: Output PRs as a JSON array of objects.

**Rationale**:
- Consistent structure whether 0, 1, or many PRs
- Easy to process with `jq '.[]'` or `jq '.[0]'`
- Matches common CLI tool conventions

### 3. Include timestamps as Unix epoch integers

**Decision**: Output `created_at` and `last_comment_at` as integer timestamps.

**Rationale**:
- Matches internal representation
- Unambiguous (no timezone issues)
- Easy to convert in downstream tools

### 4. Add json flag to Args structs

**Decision**: Add `json: bool = false` to both MineArgs and TeamArgs.

**Rationale**:
- Simple boolean flag
- Default false preserves current behavior
- Consistent across both commands

## Risks / Trade-offs

**[Risk]** Large PR lists could produce large JSON output
→ Acceptable - `--limit` flag already constrains output size

**[Risk]** JSON output doesn't show computed fields (age, formatted duration)
→ By design - raw data allows consumers to compute what they need
