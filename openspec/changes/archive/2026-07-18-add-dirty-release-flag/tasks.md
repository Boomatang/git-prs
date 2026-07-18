## 1. Implementation

- [x] 1.1 Add `b.option(bool, "dirty", ...)` to `build.zig`
- [x] 1.2 Conditionally replace the pre-flight shell command with a no-op (`true`) when dirty is set

## 2. Verification

- [x] 2.1 Run `zig build release -Ddirty` on current branch and confirm artifacts are produced
- [x] 2.2 Run `zig build --help` and confirm `-Ddirty` appears in the output
