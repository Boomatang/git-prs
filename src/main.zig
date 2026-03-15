const std = @import("std");
const git_prs = @import("git_prs");
const build_options = @import("build_options");

const cli = git_prs.cli;
const config = git_prs.config;
const github = git_prs.github;
const formatter = git_prs.formatter;
const time = git_prs.time;

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
            error.InvalidDateValue => {
                _ = try stderr.write("Invalid date value. Must be in YYYY-MM-DD format.\n");
            },
            error.DaysWithDateRange => {
                _ = try stderr.write("Error: --days is mutually exclusive with --since or --until.\n");
            },
            error.InvalidDaysValue => {
                _ = try stderr.write("Invalid days value. Must be a number.\n");
            },
        }
        var buf: [4096]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        cli.printUsage(fbs.writer()) catch {};
        _ = stderr.write(fbs.getWritten()) catch {};
        std.process.exit(1);
    };

    switch (command) {
        .help => |help_target| {
            var buf: [4096]u8 = undefined;
            var fbs = std.io.fixedBufferStream(&buf);
            switch (help_target) {
                .main => cli.printUsage(fbs.writer()) catch {},
                .mine => cli.printMineHelp(fbs.writer()) catch {},
                .team => cli.printTeamHelp(fbs.writer()) catch {},
                .merged => cli.printMergedHelp(fbs.writer()) catch {},
            }
            _ = stdout.write(fbs.getWritten()) catch {};
            return;
        },
        .version => |version_args| {
            if (version_args.json) {
                _ = try stdout.write("{\"name\":\"" ++ build_options.name ++ "\",\"version\":\"" ++ build_options.version ++ "\"}\n");
            } else {
                _ = try stdout.write(build_options.name ++ " " ++ build_options.version ++ "\n");
            }
            return;
        },
        .mine => |mine_args| {
            try runMineCommand(allocator, stdout, stderr, mine_args);
        },
        .team => |team_args| {
            try runTeamCommand(allocator, stdout, stderr, team_args);
        },
        .merged => |merged_args| {
            try runMergedCommand(allocator, stdout, stderr, merged_args);
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

    // Fetch PRs with date filters from CLI
    const prs = github.fetchUserPRs(&client, cfg.mine_orgs, args.org_filter, args.limit, args.since, args.until) catch |err| {
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

    // Team selection logic: explicit name > default > single-team auto-select > error
    const selected_team_name = blk: {
        // 1. If explicit team name provided, use that
        if (args.team_name) |team_name| {
            if (!cfg.teams.teams.contains(team_name)) {
                var buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "Team '{s}' not found in config\n", .{team_name}) catch "Team not found\n";
                _ = stderr.write(msg) catch {};
                std.process.exit(1);
            }
            break :blk team_name;
        }

        // 2. If default is set, use that
        if (cfg.teams.default) |default_team| {
            break :blk default_team;
        }

        // 3. If only one team, auto-select
        const team_count = cfg.teams.teams.count();
        if (team_count == 0) {
            _ = stderr.write("No teams configured in config file\n") catch {};
            std.process.exit(1);
        } else if (team_count == 1) {
            var it = cfg.teams.teams.iterator();
            if (it.next()) |entry| {
                break :blk entry.key_ptr.*;
            }
            unreachable;
        }

        // 4. Multiple teams without default and no explicit name -> error
        _ = stderr.write("Multiple teams configured. Specify team name or set default in config.\n") catch {};
        _ = stderr.write("Available teams: ") catch {};
        var it = cfg.teams.teams.iterator();
        var first = true;
        while (it.next()) |entry| {
            if (!first) {
                _ = stderr.write(", ") catch {};
            }
            _ = stderr.write(entry.key_ptr.*) catch {};
            first = false;
        }
        _ = stderr.write("\n") catch {};
        std.process.exit(1);
    };

    // Get the selected team configuration
    const team_config = cfg.teams.teams.get(selected_team_name) orelse {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Team '{s}' not found in config\n", .{selected_team_name}) catch "Team not found\n";
        _ = stderr.write(msg) catch {};
        std.process.exit(1);
    };

    // Initialize GitHub client
    var client = github.Client.init(allocator, cfg.auth_token);
    defer client.deinit();

    // Resolve effective dates: CLI overrides config
    const effective_since = args.since orelse team_config.since;
    const effective_until = args.until orelse team_config.until;

    // Fetch PRs for all orgs in the team
    var all_prs: std.ArrayListUnmanaged(github.PullRequest) = .empty;
    defer {
        for (all_prs.items) |*pr| {
            pr.deinit(allocator);
        }
        all_prs.deinit(allocator);
    }

    for (team_config.orgs) |org| {
        // Skip org if --org filter is set and doesn't match
        if (args.org) |org_filter| {
            if (!std.mem.eql(u8, org, org_filter)) {
                continue;
            }
        }

        const prs = github.fetchTeamPRs(&client, org, team_config.members, args.member_filter, effective_since, effective_until) catch |err| {
            handleGitHubError(err, stderr);
            std.process.exit(1);
        };
        defer allocator.free(prs);

        for (prs) |pr| {
            try all_prs.append(allocator, pr);
        }
    }

    // Format and output using buffer
    var output_buf: [65536]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&output_buf);

    if (args.json) {
        try formatter.formatJsonOutput(fbs.writer(), all_prs.items);
    } else {
        // Get current time for age calculations
        const current_time = std.time.timestamp();
        try formatter.formatTeamOutput(allocator, fbs.writer(), all_prs.items, current_time);
    }
    _ = try stdout.write(fbs.getWritten());
}

fn runMergedCommand(
    allocator: std.mem.Allocator,
    stdout: std.fs.File,
    stderr: std.fs.File,
    args: cli.MergedArgs,
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

    // Determine date range
    const days_to_use = args.days orelse 7; // default to 7 days
    const since_date = if (args.since) |since|
        since
    else blk: {
        const date = time.getDateDaysAgo(allocator, days_to_use) catch {
            _ = stderr.write("Failed to calculate date range\n") catch {};
            std.process.exit(1);
        };
        break :blk date;
    };
    defer {
        if (args.since == null) {
            allocator.free(since_date);
        }
    }

    // Fetch merged PRs with date filters
    const prs = github.fetchMergedPRs(&client, cfg.mine_orgs, args.org_filter, since_date, args.until) catch |err| {
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
        // Use plain URL output
        try formatter.formatMergedUrlOutput(fbs.writer(), prs, days_to_use);
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
        error.EmptyTeamOrgs => {
            _ = stderr.write("Config error: team has empty orgs array\n") catch {};
        },
        error.MissingTeamOrgs => {
            _ = stderr.write("Config error: team must have 'orgs' field\n") catch {};
        },
        error.InvalidDefaultTeam => {
            _ = stderr.write("Config error: 'default' references non-existent team\n") catch {};
        },
        error.NoDefaultTeam => {
            _ = stderr.write("Config error: multiple teams configured but no default specified\n") catch {};
        },
        error.InvalidDateFormat => {
            _ = stderr.write("Config error: Invalid date format. Use YYYY-MM-DD format.\n") catch {};
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
