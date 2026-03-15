## Context

The current CLI implementation in `src/cli.zig` uses manual argument parsing with ~400 lines of custom parsing code. Each command (`mine`, `team`, `merged`) has its own parsing function with repetitive flag handling logic. The help text is manually maintained in `printUsage()` and must be kept in sync with the actual argument definitions.

The codebase already has well-defined command structures (`MineArgs`, `TeamArgs`, `MergedArgs`, `VersionArgs`) and a `Command` union that routes to handlers in `main.zig`. These structures should be preserved as they're used throughout the application.

## Goals / Non-Goals

**Goals:**
- Replace manual argument parsing with zig-clap's declarative API
- Automatic help generation from parameter definitions
- Maintain identical CLI behavior (all commands, options, defaults)
- Reduce boilerplate and improve maintainability
- Keep existing `*Args` structs and `Command` union

**Non-Goals:**
- Changing the CLI interface or adding new commands
- Modifying command handlers in `main.zig`
- Restructuring the overall application architecture

## Decisions

### Decision 1: Use zig-clap's comptime parameter parsing

Use `clap.parseParamsComptime()` to define parameters declaratively. This provides type safety and automatic help generation at compile time.

**Rationale**: Comptime parsing catches errors at build time rather than runtime, and generates help text automatically from parameter definitions.

**Alternative considered**: Runtime parameter definition - rejected because it loses compile-time guarantees and requires more boilerplate.

### Decision 2: Implement subcommands using separate parsers

Rather than trying to use zig-clap's subcommand feature (which may have limitations), define separate parameter sets for each command and dispatch based on the first positional argument.

**Rationale**: This matches the current architecture where `parseArgs()` first identifies the command then delegates to command-specific parsing. It's also simpler to implement and debug.

**Alternative considered**: Single unified parser with all options - rejected because different commands have different valid options (e.g., `--days` only valid for `merged`).

### Decision 3: Preserve existing Args structs as output

Keep `MineArgs`, `TeamArgs`, `MergedArgs`, and `Command` union unchanged. The new clap-based parsing will populate these same structs.

**Rationale**: These structs are used by command handlers in `main.zig`. Preserving them minimizes changes to the rest of the codebase.

### Decision 4: Custom date validation with clap parsers

Use zig-clap's custom parser feature to validate YYYY-MM-DD date format during parsing, reusing the existing `isValidDateFormat()` function.

**Rationale**: Keeps validation at parse time for consistent error handling.

### Decision 5: Remove manual printUsage() function

Delete `printUsage()` and rely on zig-clap's automatic help generation.

**Rationale**: Eliminates the maintenance burden of keeping help text in sync with actual parameters.

## Risks / Trade-offs

**[Risk] zig-clap version compatibility** → Pin to a specific release tag in `build.zig.zon` and document the version requirement.

**[Risk] Subtle behavior differences in argument parsing** → Comprehensive test coverage comparing old and new parser behavior for all documented scenarios.

**[Trade-off] Learning curve** → Developers need to understand zig-clap API, but the declarative style is simpler than manual parsing.

**[Trade-off] External dependency** → Adds a third-party dependency, but zig-clap is well-maintained and widely used in the Zig ecosystem.
