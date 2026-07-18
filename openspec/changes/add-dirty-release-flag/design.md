## Context

The `release` step in `build.zig` runs a single shell command with multiple pre-flight checks before building artifacts. These checks are all in one `sh -c` invocation that gates the entire release pipeline. The dependency chain is: preflight → clean → mkdir → tar/install (per target) → checksum → gh release.

## Goals / Non-Goals

**Goals:**
- Allow `zig build release -Ddirty` to skip all pre-flight guards and build release artifacts locally.
- Keep the default behavior (no flag) unchanged — all guards enforced.

**Non-Goals:**
- Changing which pre-flight checks exist.
- Adding partial skip options (e.g., skip only the branch check).

## Decisions

- **Use `b.option(bool, "dirty", ...)` for the flag**: This is the standard Zig build system pattern for boolean options. It appears in `zig build --help` automatically. Alternative considered: environment variable — rejected because build options are the idiomatic Zig approach and integrate with the build system's help output.

- **When dirty, replace preflight with a no-op**: Rather than conditionally constructing the shell string, skip the entire preflight command when dirty is set. The preflight command is a single `addSystemCommand` whose step other steps depend on. When dirty, use a no-op system command (`true`) so the dependency chain remains intact. This avoids restructuring the step graph.

## Risks / Trade-offs

- [Accidental dirty release to GitHub] → The `gh release create` command at the end of the pipeline will still run. However, this is mitigated by the fact that the user must explicitly pass `-Ddirty`, and a dirty build on a non-main branch is unlikely to have the correct version tag. The gh CLI will also require authentication.
