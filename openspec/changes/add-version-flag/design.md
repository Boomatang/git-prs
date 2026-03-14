## Context

The CLI currently supports commands (`mine`, `team`, `merged`) and a `--help` flag. Version information is defined in `build.zig.zon` but not accessible at runtime. The build system uses Zig 0.15.2 which supports reading zon files and injecting build options.

Current CLI structure:
- `cli.zig`: Defines `Command` union and `parseArgs` function
- `main.zig`: Handles command dispatch
- `build.zig`: Configures the build, creates modules and executable
- `build.zig.zon`: Contains `.name = .git_prs` and `.version = "0.0.0"`

## Goals / Non-Goals

**Goals:**
- Add `--version` flag that prints `git-prs X.Y.Z` and exits
- Source version and name from `build.zig.zon` at compile time
- Follow the same pattern as `--help` for consistency

**Non-Goals:**
- Short form `-V` flag
- Git commit hash or build date in version output
- Embedding the zon file at runtime

## Decisions

### 1. Build-time option injection

**Decision**: Use Zig's build options system to pass version and name from zon to compiled code.

**Rationale**: This is the idiomatic Zig approach. The build system can access the zon file via `@import("build.zig.zon")` and pass values as compile-time options that code accesses via `@import("build_options")`.

**Alternatives considered**:
- `@embedFile` the zon and parse at runtime: Wasteful, adds runtime parsing
- Hardcode version in source: Requires updating multiple places

### 2. Name transformation

**Decision**: Transform `.name = .git_prs` (identifier) to `"git-prs"` (display string) in build.zig.

**Rationale**: The zon file uses an identifier (`.git_prs`) which cannot contain hyphens. The display name should match the conventional CLI name `git-prs`. The build script will convert underscores to hyphens.

### 3. Command union extension

**Decision**: Add `version: void` variant to the `Command` union, matching the existing `help: void` pattern.

**Rationale**: Consistent with existing code structure. Both are informational flags that print output and exit.

## Risks / Trade-offs

**Risk**: Zon format changes in future Zig versions
→ Mitigation: Using stable `@import` mechanism; changes would be caught at build time

**Trade-off**: Name transformation logic lives in build.zig
→ Acceptable: Single point of transformation, easy to modify if naming convention changes
