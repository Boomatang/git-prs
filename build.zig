const std = @import("std");
const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dirty = b.option(bool, "dirty", "Skip release pre-flight checks (branch, clean tree, etc.)") orelse false;
    // Add clap dependency
    const clap = b.dependency("clap", .{});
    const name_str = @tagName(zon.name);
    // Convert underscores to hyphens for display name (git_prs -> git-prs)
    var display_name_buf: [64]u8 = undefined;
    var display_name_len: usize = 0;
    for (name_str) |c| {
        display_name_buf[display_name_len] = if (c == '_') '-' else c;
        display_name_len += 1;
    }
    const display_name = display_name_buf[0..display_name_len];

    // Create build options module with version and name
    const options = b.addOptions();
    options.addOption([]const u8, "name", display_name);
    options.addOption([]const u8, "version", zon.version);

    const mod = b.addModule("git_prs", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "clap", .module = clap.module("clap") },
        },
    });

    const exe = b.addExecutable(.{
        .name = "git_prs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "git_prs", .module = mod },
                .{ .name = "build_options", .module = options.createModule() },
                .{ .name = "clap", .module = clap.module("clap") },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .aarch64, .os_tag = .linux },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
    };

    // Create top-level artifacts step
    const artifacts_step = b.step("artifacts", "Build release artifacts for all targets");

    for (targets) |t| {
        // Determine OS and architecture strings for naming
        const os_str = if (t.os_tag.? == .linux) "linux" else "macos";
        const arch_str = if (t.cpu_arch.? == .x86_64) "x86_64" else "aarch64";

        // Create cross-compiled executable with ReleaseSmall optimization
        const cross_exe = b.addExecutable(.{
            .name = name_str,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(t),
                .optimize = .ReleaseSmall,
                .imports = &.{
                    .{ .name = "git_prs", .module = mod },
                    .{ .name = "build_options", .module = options.createModule() },
                    .{ .name = "clap", .module = clap.module("clap") },
                },
            }),
        });

        // Install the executable - this returns the installed file path
        const install_exe = b.addInstallArtifact(cross_exe, .{});

        // Create archive name: git_prs-{version}-{os}-{arch}.tar.gz
        const archive_name = b.fmt("{s}-{s}-{s}-{s}.tar.gz", .{ name_str, zon.version, os_str, arch_str });

        // Create mkdir command to ensure artifacts directory exists
        const mkdir_cmd = b.addSystemCommand(&.{
            "mkdir",
            "-p",
            "zig-out/artifacts",
        });

        // Create tar archive using system tar command
        // The executable will be in the archive as just "git_prs" (no subdirectory)
        const tar_cmd = b.addSystemCommand(&.{
            "tar",
            "-czf",
        });
        tar_cmd.addArg(b.fmt("zig-out/artifacts/{s}", .{archive_name}));
        tar_cmd.addArg("--transform");
        tar_cmd.addArg("s|.*/||");
        tar_cmd.addFileArg(install_exe.emitted_bin.?);
        tar_cmd.step.dependOn(&install_exe.step);
        tar_cmd.step.dependOn(&mkdir_cmd.step);

        // Create SHA256 checksum using sha256sum
        // Format: <hash>  <filename> (two spaces)
        const checksum_cmd = b.addSystemCommand(&.{
            "sh",
            "-c",
            b.fmt("cd zig-out/artifacts && sha256sum {s} > {s}.sha256", .{ archive_name, archive_name }),
        });
        checksum_cmd.step.dependOn(&tar_cmd.step);

        // Add this target's checksum step to the artifacts step
        artifacts_step.dependOn(&checksum_cmd.step);
    }

    // Release Step - Create a GitHub release with artifacts
    const release_step = b.step("release", "Create a GitHub release");

    // Pre-flight checks - single shell command that runs all checks in sequence
    const preflight_cmd = if (dirty) b.addSystemCommand(&.{ "true" }) else b.addSystemCommand(&.{
        "sh",
        "-c",
        b.fmt(
            \\command -v gh >/dev/null 2>&1 || {{ echo "Error: gh CLI not found. Install from https://cli.github.com/"; exit 1; }}
            \\[ -z "$(git status --porcelain)" ] || {{ echo "Error: Working directory not clean. Commit or stash changes first."; exit 1; }}
            \\[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || {{ echo "Error: Must be on main branch to release."; exit 1; }}
            \\git fetch origin main
            \\[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || {{ echo "Error: Local main is not in sync with origin/main. Push or pull first."; exit 1; }}
            \\[ -z "$(git tag -l "v{s}")" ] || {{ echo "Error: Tag v{s} already exists."; exit 1; }}
            \\! gh release view "v{s}" >/dev/null 2>&1 || {{ echo "Error: Release v{s} already exists on GitHub."; exit 1; }}
        , .{ zon.version, zon.version, zon.version, zon.version }),
    });

    // Clean command to remove artifacts directory
    const clean_cmd = b.addSystemCommand(&.{
        "rm",
        "-rf",
        "zig-out/artifacts",
    });
    clean_cmd.step.dependOn(&preflight_cmd.step);

    // Build artifacts for all targets (same loop as artifacts step)
    var checksum_steps: [targets.len]*std.Build.Step.Run = undefined;
    for (targets, 0..) |t, i| {
        // Determine OS and architecture strings for naming
        const os_str = if (t.os_tag.? == .linux) "linux" else "macos";
        const arch_str = if (t.cpu_arch.? == .x86_64) "x86_64" else "aarch64";

        // Create cross-compiled executable with ReleaseSmall optimization
        const cross_exe = b.addExecutable(.{
            .name = name_str,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(t),
                .optimize = .ReleaseSmall,
                .imports = &.{
                    .{ .name = "git_prs", .module = mod },
                    .{ .name = "build_options", .module = options.createModule() },
                    .{ .name = "clap", .module = clap.module("clap") },
                },
            }),
        });

        // Install the executable
        const install_exe = b.addInstallArtifact(cross_exe, .{});

        // Create archive name
        const archive_name = b.fmt("{s}-{s}-{s}-{s}.tar.gz", .{ name_str, zon.version, os_str, arch_str });

        // Create mkdir command
        const mkdir_cmd = b.addSystemCommand(&.{
            "mkdir",
            "-p",
            "zig-out/artifacts",
        });
        mkdir_cmd.step.dependOn(&clean_cmd.step);

        // Create tar archive
        const tar_cmd = b.addSystemCommand(&.{
            "tar",
            "-czf",
        });
        tar_cmd.addArg(b.fmt("zig-out/artifacts/{s}", .{archive_name}));
        tar_cmd.addArg("--transform");
        tar_cmd.addArg("s|.*/||");
        tar_cmd.addFileArg(install_exe.emitted_bin.?);
        tar_cmd.step.dependOn(&install_exe.step);
        tar_cmd.step.dependOn(&mkdir_cmd.step);

        // Create SHA256 checksum
        const checksum_cmd = b.addSystemCommand(&.{
            "sh",
            "-c",
            b.fmt("cd zig-out/artifacts && sha256sum {s} > {s}.sha256", .{ archive_name, archive_name }),
        });
        checksum_cmd.step.dependOn(&tar_cmd.step);

        // Store checksum step for later dependency
        checksum_steps[i] = checksum_cmd;
    }

    // Create GitHub release with all artifacts
    const gh_release_cmd = b.addSystemCommand(&.{
        "sh",
        "-c",
        b.fmt("gh release create v{s} --draft --title '{s} v{s}' --generate-notes zig-out/artifacts/*.tar.gz zig-out/artifacts/*.sha256", .{ zon.version, display_name, zon.version }),
    });

    // Depend on all checksum steps completing
    for (checksum_steps) |checksum_step| {
        gh_release_cmd.step.dependOn(&checksum_step.step);
    }

    // Add gh release command to release step
    release_step.dependOn(&gh_release_cmd.step);

    // Set Up Changie Commands
    // WARNING: build() returns early here if changie deps are not fetched.
    // Do NOT add build steps after the changie block — they will be silently hidden.
    const changie_bin = get_changie_bin(b) orelse return;

    // Changie Add
    const changie_add = std.Build.Step.Run.create(b, "run changie");
    changie_add.addFileArg(changie_bin);
    changie_add.addArg("new");
    const changie_add_cmd = b.step("changie:add", "Add change log fragment");
    changie_add_cmd.dependOn(&changie_add.step);

    // Changie batch
    const changie_batch = std.Build.Step.Run.create(b, "run changie");
    changie_batch.addFileArg(changie_bin);
    changie_batch.addArg("batch");
    changie_batch.addArg(zon.version);
    const changie_batch_cmd = b.step("changie:batch", "Batch fragments for a release");
    changie_batch_cmd.dependOn(&changie_batch.step);

    // Changie merge
    const changie_merge = std.Build.Step.Run.create(b, "run changie");
    changie_merge.addFileArg(changie_bin);
    changie_merge.addArg("merge");
    const changie_merge_cmd = b.step("changie:merge", "Merge all changes into CHANGELOG.md");
    changie_merge_cmd.dependOn(&changie_merge.step);

    // Changie Version
    const changie_version = std.Build.Step.Run.create(b, "run changie");
    changie_version.addFileArg(changie_bin);
    changie_version.addArg("--version");
    const changie_version_cmd = b.step("changie:version", "Print the changie version");
    changie_version_cmd.dependOn(&changie_version.step);
}

fn get_changie_bin(b: *std.Build) ?std.Build.LazyPath {
    const host = b.graph.host.result;
    const name = switch (host.os.tag) {
        .linux => switch (host.cpu.arch) {
            .x86_64 => "changie_linux_amd64",
            .aarch64 => "changie_linux_arm64",
            else => return null,
        },
        .macos => switch (host.cpu.arch) {
            .x86_64 => "changie_darwin_amd64",
            .aarch64 => "changie_darwin_arm64",
            else => return null,
        },

        else => return null,
    };

    if (b.lazyDependency(name, .{})) |dep| {
        return dep.path("changie");
    } else {
        return null;
    }
}
