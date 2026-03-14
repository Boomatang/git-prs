## 1. Target Matrix Setup

- [ ] 1.1 Define target array with all 4 cross-compilation targets (x86_64-linux, aarch64-linux, x86_64-macos, aarch64-macos)
- [ ] 1.2 Extract name and version from build.zig.zon for use in artifact naming

## 2. Cross-Compilation

- [ ] 2.1 Create executable compile step for each target with ReleaseSmall optimization
- [ ] 2.2 Generate target-specific output paths for compiled binaries

## 3. Archive Creation

- [ ] 3.1 Create tar.gz archive step using system tar command for each target
- [ ] 3.2 Implement archive naming convention: git_prs-{version}-{os}-{arch}.tar.gz
- [ ] 3.3 Ensure binary inside archive is named git_prs

## 4. Checksum Generation

- [ ] 4.1 Implement SHA256 checksum calculation for each archive
- [ ] 4.2 Write .sha256 files in sha256sum compatible format

## 5. Artifacts Step

- [ ] 5.1 Create top-level "artifacts" step that depends on all archive and checksum steps
- [ ] 5.2 Configure output directory as zig-out/artifacts/

## 6. Verification

- [ ] 6.1 Run zig build artifacts and verify all 8 files created (4 archives + 4 checksums)
- [ ] 6.2 Verify checksums with sha256sum -c *.sha256
- [ ] 6.3 Extract an archive and verify binary name and executability
