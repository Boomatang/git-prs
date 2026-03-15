## Context

Currently `--version` is checked early in argument parsing and returns immediately with a simple enum value. The `--json` flag is only parsed within subcommand argument parsers (`parseMineArgs`, `parseTeamArgs`, `parseMergedArgs`).

To support `--version --json`, the parsing logic needs to scan all arguments for both flags before deciding what to do.

## Goals / Non-Goals

**Goals:**
- Support `--json` modifier with `--version` flag
- Allow either argument order (`--version --json` or `--json --version`)
- Allow `--version` anywhere in args (e.g., `mine --version` shows version)
- Maintain backward compatibility for plain `--version`

**Non-Goals:**
- Adding other global flags (can be done later with same pattern)
- Changing JSON output format for other commands
- Adding build commit/hash to version output

## Decisions

### 1. Version command gets a json field

**Decision:** Change `.version` from a simple enum tag to a struct with a `json: bool` field, matching how `mine`, `team`, and `merged` work.

**Rationale:** Consistency with existing command structures. The pattern already exists and works well.

**Alternative considered:** Global `--json` flag parsed separately. Rejected because it would require refactoring all command parsing.

### 2. Scan all args for --version first

**Decision:** Before any subcommand parsing, scan the entire argument list for `--version`. If found, also scan for `--json`, then return the version command.

**Rationale:** This makes `--version` an escape hatch that works anywhere in the argument list, matching user expectations from tools like `git` and `docker`.

**Alternative considered:** Only allow `--version` as first argument. Rejected for poorer UX.

### 3. JSON output format

**Decision:** Output `{"name":"git-prs","version":"0.1.0"}` with name and version fields.

**Rationale:** Provides enough information for scripting while staying minimal. Name included for verification in multi-tool scripts.

## Risks / Trade-offs

- **[Slight parsing overhead]** → Scanning all args adds minimal overhead; argument lists are typically small
- **[Order-independent parsing]** → Could theoretically cause confusion if someone expects strict ordering, but this matches common CLI conventions
