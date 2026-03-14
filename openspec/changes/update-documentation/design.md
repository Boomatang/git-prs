## Context

The project currently has no README or user documentation. The only docs are internal design specs in `docs/superpowers/specs/` and openspec change artifacts. Users must read source code to understand usage.

## Goals / Non-Goals

**Goals:**
- Enable new users to install and configure git-prs without reading source
- Document all CLI commands and flags
- Provide config file examples and troubleshooting guidance
- Keep docs maintainable and in sync with code

**Non-Goals:**
- API documentation (no public API)
- Developer/contributor guide (future work)
- Automated doc generation from code

## Decisions

### 1. Documentation structure

**Decision**: Three separate docs - README.md in root, detailed docs in `docs/` folder.

**Rationale**:
- README.md is the standard entry point for GitHub projects
- Separate CLI reference and config guide keeps each doc focused
- `docs/` folder follows common convention

### 2. README content scope

**Decision**: README covers overview, prerequisites, installation, quick start, and links to detailed docs.

**Rationale**:
- Quick start gets users running in under 2 minutes
- Detailed docs handle edge cases and advanced usage
- Avoids README becoming too long

### 3. Config examples

**Decision**: Include both minimal and full config examples with comments.

**Rationale**:
- Minimal example shows simplest valid config
- Full example documents all options
- Comments explain non-obvious fields

## Risks / Trade-offs

**[Risk]** Docs become outdated as features change
→ Keep docs focused on stable features; reference tasks.md for pending changes

**[Risk]** Duplicating information between README and detailed docs
→ README links to detailed docs rather than repeating content
