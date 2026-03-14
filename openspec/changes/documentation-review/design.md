## Context

The git-prs documentation was established during initial implementation but has not kept pace with feature development. The current state:

- **README.md**: Lists 6 features but is missing merged PRs, date filtering, named teams
- **docs/cli-reference.md**: Documents `mine` and `team` commands but missing `merged` command, date filtering options, and named teams syntax
- **docs/config-guide.md**: Shows old team configuration format, missing named teams structure

Recent additions not documented:
- `merged` command (6b6587c)
- Draft PR styling (b50a567)
- Named teams with multi-org support (827b53a)
- Dynamic author width (c86367b)
- Date filtering `--since`/`--until` (971afb6)
- Inline URL display when terminal is wide (5d3fb3d)
- Terminal width detection (078bc66)

## Goals / Non-Goals

**Goals:**
- Document all current CLI commands and options accurately
- Update configuration guide with named teams format
- Keep documentation style consistent with existing docs
- Provide clear examples for new features

**Non-Goals:**
- Restructuring documentation organization
- Adding new documentation formats (man pages, etc.)
- Documenting internal implementation details
- Adding screenshots or visual assets

## Decisions

### 1. Update existing files rather than create new ones

**Decision**: Modify README.md, cli-reference.md, and config-guide.md in place.

**Rationale**: The existing structure is adequate. Adding new files would fragment the documentation and create maintenance burden.

**Alternatives considered**:
- Create separate docs per feature (rejected: inconsistent user experience)
- Single comprehensive doc (rejected: existing structure works well)

### 2. Document display behaviors briefly in CLI reference

**Decision**: Add a "Display Features" section to cli-reference.md covering terminal width detection, inline URLs, draft PR styling, and dynamic column widths.

**Rationale**: These are user-visible behaviors tied to CLI usage. Users need to know what to expect visually.

### 3. Named teams configuration as primary format

**Decision**: Present named teams as the primary configuration format in config-guide.md while keeping the legacy format documented for backwards compatibility.

**Rationale**: Named teams is the more powerful and flexible approach. New users should learn this format first.

## Risks / Trade-offs

**[Docs become stale again]** → Include documentation update reminder in future feature OpenSpec templates

**[Breaking examples if config format changed]** → Verify all examples against current implementation before finalizing
