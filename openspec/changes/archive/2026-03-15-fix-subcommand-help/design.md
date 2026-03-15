## Context

The CLI parser uses zig-clap for argument parsing. When a subcommand like `mine` receives `--help`, the parser correctly detects it via `res.args.help != 0`, but returns a bare `.help` variant (which is `void`). In `main.zig`, the switch on `.help` always calls `printUsage()` - the top-level help - because there's no way to know which subcommand triggered the help request.

The subcommand-specific help functions (`printMineHelp`, `printTeamHelp`, `printMergedHelp`) already exist in `cli.zig` but are never called.

## Goals / Non-Goals

**Goals:**
- `git-prs mine --help` shows mine-specific help
- `git-prs team --help` shows team-specific help
- `git-prs merged --help` shows merged-specific help
- `git-prs --help` continues to show top-level help

**Non-Goals:**
- Changing the content of help messages
- Adding new help formatting features
- Supporting `-h` differently from `--help`

## Decisions

### Decision 1: Add HelpTarget enum to Command union

**Choice**: Change `help: void` to `help: HelpTarget` where `HelpTarget = enum { main, mine, team, merged }`

**Rationale**: This is the minimal change that carries context through the existing data flow. The parser already returns a Command, so enriching the help variant is natural.

**Alternatives considered**:
- Print help directly in parse functions: Mixes parsing with I/O, harder to test
- Return a separate "exit code" type: More invasive change, breaks existing pattern
- Use clap's built-in help: Would require passing stdout to parse functions

### Decision 2: Update parse functions to return specific help target

**Choice**: Each `parseXCommand` function returns `.{ .help = .X }` when help is requested

**Rationale**: The subcommand context is known at parse time; this is where the information should be captured.

## Risks / Trade-offs

- **Test updates required** → Minor: Tests checking for `.help` need to specify the target enum
- **Breaking change for any external code using Command** → Low risk: This is an internal CLI tool with no external consumers
