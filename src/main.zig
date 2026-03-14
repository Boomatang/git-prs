const std = @import("std");
const git_prs = @import("git_prs");

const cli = git_prs.cli;
const config = git_prs.config;
const github = git_prs.github;
const formatter = git_prs.formatter;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stderr = std.fs.File.stderr();
    const stdout = std.fs.File.stdout();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Skip the program name (args[0])
    const cli_args = if (args.len > 1) args[1..] else args[0..0];

    const command = cli.parseArgs(allocator, cli_args) catch |err| {
        switch (err) {
            error.UnknownCommand => {
                _ = try stderr.write("Unknown command. Use 'mine' or 'team'.\n");
            },
            error.InvalidFlag => {
                _ = try stderr.write("Invalid flag.\n");
            },
            error.MissingFlagValue => {
                _ = try stderr.write("Missing value for flag.\n");
            },
            error.InvalidLimitValue => {
                _ = try stderr.write("Invalid limit value. Must be a number.\n");
            },
        }
        var buf: [4096]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        cli.printUsage(fbs.writer()) catch {};
        _ = stderr.write(fbs.getWritten()) catch {};
        std.process.exit(1);
    };

    switch (command) {
        .help => {
            var buf: [4096]u8 = undefined;
            var fbs = std.io.fixedBufferStream(&buf);
            cli.printUsage(fbs.writer()) catch {};
            _ = stdout.write(fbs.getWritten()) catch {};
            return;
        },
        .mine => |mine_args| {
            try runMineCommand(allocator, stdout, stderr, mine_args);
        },
        .team => |team_args| {
            try runTeamCommand(allocator, stdout, stderr, team_args);
        },
    }
}

fn runMineCommand(
    allocator: std.mem.Allocator,
    stdout: std.fs.File,
    stderr: std.fs.File,
    args: cli.MineArgs,
) !void {
    // Load config
    var cfg = config.loadConfig(allocator) catch |err| {
        handleConfigError(err, stderr);
        std.process.exit(1);
    };
    defer cfg.deinit();

    // Initialize GitHub client
    var client = github.Client.init(allocator, cfg.auth_token);
    defer client.deinit();

    // Get authenticated user (needed for @me queries)
    const user = github.getAuthenticatedUser(&client) catch |err| {
        handleGitHubError(err, stderr);
        std.process.exit(1);
    };
    defer allocator.free(user);

    // Fetch PRs
    const prs = github.fetchUserPRs(&client, cfg.mine_orgs, args.org_filter, args.limit) catch |err| {
        handleGitHubError(err, stderr);
        std.process.exit(1);
    };
    defer {
        for (prs) |*pr| {
            pr.deinit(allocator);
        }
        allocator.free(prs);
    }

    // Format and output using buffer
    var output_buf: [65536]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&output_buf);

    if (args.json) {
        try formatter.formatJsonOutput(fbs.writer(), prs);
    } else {
        // Get current time for age calculations
        const current_time = std.time.timestamp();
        try formatter.formatMineOutput(allocator, fbs.writer(), prs, current_time);
    }
    _ = try stdout.write(fbs.getWritten());
}

fn runTeamCommand(
    allocator: std.mem.Allocator,
    stdout: std.fs.File,
    stderr: std.fs.File,
    args: cli.TeamArgs,
) !void {
    // Load config
    var cfg = config.loadConfig(allocator) catch |err| {
        handleConfigError(err, stderr);
        std.process.exit(1);
    };
    defer cfg.deinit();

    // Determine which org to use
    const org = blk: {
        if (args.org) |specified_org| {
            // User specified an org, verify it exists in config (case-insensitive)
            const matched_org = findTeamKeyCaseInsensitive(cfg.teams, specified_org);
            if (matched_org == null) {
                var buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "No team configured for org '{s}'\n", .{specified_org}) catch "No team configured\n";
                _ = stderr.write(msg) catch {};
                std.process.exit(1);
            }
            break :blk matched_org.?;
        } else {
            // Auto-select if only one team configured
            const team_count = cfg.teams.count();
            if (team_count == 0) {
                _ = stderr.write("No teams configured in config file\n") catch {};
                std.process.exit(1);
            } else if (team_count == 1) {
                // Auto-select the single team
                var it = cfg.teams.iterator();
                if (it.next()) |entry| {
                    break :blk entry.key_ptr.*;
                }
                unreachable;
            } else {
                // Multiple teams, need to specify
                _ = stderr.write("Multiple teams configured. Specify --org\n") catch {};
                std.process.exit(1);
            }
        }
    };

    // Get team members for this org
    const members = cfg.teams.get(org) orelse {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "No team configured for org '{s}'\n", .{org}) catch "No team configured\n";
        _ = stderr.write(msg) catch {};
        std.process.exit(1);
    };

    // Initialize GitHub client
    var client = github.Client.init(allocator, cfg.auth_token);
    defer client.deinit();

    // Fetch PRs
    const prs = github.fetchTeamPRs(&client, org, members, args.member_filter) catch |err| {
        handleGitHubError(err, stderr);
        std.process.exit(1);
    };
    defer {
        for (prs) |*pr| {
            pr.deinit(allocator);
        }
        allocator.free(prs);
    }

    // Format and output using buffer
    var output_buf: [65536]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&output_buf);

    if (args.json) {
        try formatter.formatJsonOutput(fbs.writer(), prs);
    } else {
        // Get current time for age calculations
        const current_time = std.time.timestamp();
        try formatter.formatTeamOutput(allocator, fbs.writer(), prs, current_time);
    }
    _ = try stdout.write(fbs.getWritten());
}

fn handleConfigError(err: anyerror, stderr: std.fs.File) void {
    switch (err) {
        error.ConfigNotFound => {
            // Error message already printed by config module
        },
        error.InvalidJson => {
            _ = stderr.write("Invalid config: JSON parse error\n") catch {};
        },
        error.MissingMineOrgs => {
            _ = stderr.write("Config error: mine.orgs must contain at least one org\n") catch {};
        },
        error.EmptyMineOrgs => {
            _ = stderr.write("Config error: mine.orgs must contain at least one org\n") catch {};
        },
        error.EmptyOrgName => {
            _ = stderr.write("Config error: mine.orgs contains empty org name\n") catch {};
        },
        error.EmptyTeamMembers => {
            _ = stderr.write("Config error: team has no members listed\n") catch {};
        },
        error.GhNotInstalled => {
            // Error message already printed by config module
        },
        error.NotAuthenticated => {
            // Error message already printed by config module
        },
        else => {
            _ = stderr.write("Failed to load config\n") catch {};
        },
    }
}

/// Find a team config key case-insensitively
/// Returns the actual key from the config if a case-insensitive match is found
fn findTeamKeyCaseInsensitive(teams: anytype, search_key: []const u8) ?[]const u8 {
    var it = teams.iterator();
    while (it.next()) |entry| {
        if (std.ascii.eqlIgnoreCase(entry.key_ptr.*, search_key)) {
            return entry.key_ptr.*;
        }
    }
    return null;
}

test "findTeamKeyCaseInsensitive - matches case-insensitively" {
    var teams = std.StringHashMap([]const []const u8).init(std.testing.allocator);
    defer teams.deinit();

    const members: []const []const u8 = &.{"alice"};
    try teams.put("Kubernetes", members);

    // Should match with different casings
    try std.testing.expectEqualStrings("Kubernetes", findTeamKeyCaseInsensitive(teams, "kubernetes").?);
    try std.testing.expectEqualStrings("Kubernetes", findTeamKeyCaseInsensitive(teams, "KUBERNETES").?);
    try std.testing.expectEqualStrings("Kubernetes", findTeamKeyCaseInsensitive(teams, "KuBeRnEtEs").?);
    try std.testing.expectEqualStrings("Kubernetes", findTeamKeyCaseInsensitive(teams, "Kubernetes").?);

    // Should not match different string
    try std.testing.expectEqual(@as(?[]const u8, null), findTeamKeyCaseInsensitive(teams, "kubernetess"));
    try std.testing.expectEqual(@as(?[]const u8, null), findTeamKeyCaseInsensitive(teams, "openshift"));
}

fn handleGitHubError(err: anyerror, stderr: std.fs.File) void {
    switch (err) {
        error.AuthError => {
            _ = stderr.write("Authentication failed. Your token may have expired. Run `gh auth login`.\n") catch {};
        },
        error.RateLimitExceeded => {
            _ = stderr.write("GitHub API rate limit exceeded. Try again later.\n") catch {};
        },
        error.NetworkError => {
            _ = stderr.write("Failed to reach GitHub API. Check your network connection.\n") catch {};
        },
        error.ParseError => {
            _ = stderr.write("Failed to parse GitHub API response.\n") catch {};
        },
        error.GhCommandFailed => {
            _ = stderr.write("GitHub CLI command failed.\n") catch {};
        },
        else => {
            _ = stderr.write("GitHub API error\n") catch {};
        },
    }
}
