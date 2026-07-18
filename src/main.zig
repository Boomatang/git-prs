const std = @import("std");
const git_prs = @import("git_prs");
const build_options = @import("build_options");

const cli = git_prs.cli;
const config = git_prs.config;
const github = git_prs.github;
const formatter = git_prs.formatter;
const time = git_prs.time;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const stderr = std.Io.File.stderr();
    const stdout = std.Io.File.stdout();

    // Collect command line arguments, skipping program name
    var args_iter = std.process.Args.Iterator.init(init.minimal.args);
    _ = args_iter.skip();
    var args_buf: [64][]const u8 = undefined;
    var args_count: usize = 0;
    while (args_iter.next()) |arg| {
        args_buf[args_count] = arg;
        args_count += 1;
    }
    const cli_args = args_buf[0..args_count];

    const command = cli.parseArgs(allocator, cli_args) catch |err| {
        switch (err) {
            error.UnknownCommand => {
                stderr.writeStreamingAll(io, "Unknown command. Use 'mine' or 'team'.\n") catch {};
            },
            error.InvalidFlag => {
                stderr.writeStreamingAll(io, "Invalid flag.\n") catch {};
            },
            error.MissingFlagValue => {
                stderr.writeStreamingAll(io, "Missing value for flag.\n") catch {};
            },
            error.InvalidLimitValue => {
                stderr.writeStreamingAll(io, "Invalid limit value. Must be a number.\n") catch {};
            },
            error.InvalidDateValue => {
                stderr.writeStreamingAll(io, "Invalid date value. Must be in YYYY-MM-DD format.\n") catch {};
            },
            error.DaysWithDateRange => {
                stderr.writeStreamingAll(io, "Error: --days is mutually exclusive with --since or --until.\n") catch {};
            },
            error.InvalidDaysValue => {
                stderr.writeStreamingAll(io, "Invalid days value. Must be a number.\n") catch {};
            },
        }
        var buf: [4096]u8 = undefined;
        var w = stderr.writer(io, &buf);
        cli.printUsage(&w.interface) catch {};
        w.flush() catch {};
        std.process.exit(1);
    };

    switch (command) {
        .help => |help_target| {
            var buf: [4096]u8 = undefined;
            var w = stdout.writer(io, &buf);
            switch (help_target) {
                .main => cli.printUsage(&w.interface) catch {},
                .mine => cli.printMineHelp(&w.interface) catch {},
                .team => cli.printTeamHelp(&w.interface) catch {},
                .merged => cli.printMergedHelp(&w.interface) catch {},
            }
            w.flush() catch {};
            return;
        },
        .version => |version_args| {
            if (version_args.json) {
                try stdout.writeStreamingAll(io, "{\"name\":\"" ++ build_options.name ++ "\",\"version\":\"" ++ build_options.version ++ "\"}\n");
            } else {
                try stdout.writeStreamingAll(io, build_options.name ++ " " ++ build_options.version ++ "\n");
            }
            return;
        },
        .mine => |mine_args| {
            try runMineCommand(allocator, io, init.environ_map, stdout, stderr, mine_args);
        },
        .team => |team_args| {
            try runTeamCommand(allocator, io, init.environ_map, stdout, stderr, team_args);
        },
        .merged => |merged_args| {
            try runMergedCommand(allocator, io, init.environ_map, stdout, stderr, merged_args);
        },
    }
}

fn runMineCommand(
    allocator: std.mem.Allocator,
    io: std.Io,
    environ_map: *std.process.Environ.Map,
    stdout: std.Io.File,
    stderr: std.Io.File,
    args: cli.MineArgs,
) !void {
    var cfg = config.loadConfig(allocator, io, environ_map) catch |err| {
        handleConfigError(err, io, stderr);
        std.process.exit(1);
    };
    defer cfg.deinit();

    var client = github.Client.init(allocator, io, cfg.auth_token);
    defer client.deinit();

    const user = github.getAuthenticatedUser(&client) catch |err| {
        handleGitHubError(err, io, stderr);
        std.process.exit(1);
    };
    defer allocator.free(user);

    const prs = github.fetchUserPRs(&client, cfg.mine_orgs, args.org_filter, args.limit, args.since, args.until) catch |err| {
        handleGitHubError(err, io, stderr);
        std.process.exit(1);
    };
    defer {
        for (prs) |*pr| {
            pr.deinit(allocator);
        }
        allocator.free(prs);
    }

    var output_buf: [65536]u8 = undefined;
    var w = stdout.writer(io, &output_buf);

    if (args.json) {
        try formatter.formatJsonOutput(&w.interface, prs);
    } else {
        const current_time = std.Io.Timestamp.now(io, .real).toSeconds();
        try formatter.formatMineOutput(allocator, &w.interface, prs, current_time, io, environ_map);
    }
    try w.flush();
}

fn runTeamCommand(
    allocator: std.mem.Allocator,
    io: std.Io,
    environ_map: *std.process.Environ.Map,
    stdout: std.Io.File,
    stderr: std.Io.File,
    args: cli.TeamArgs,
) !void {
    var cfg = config.loadConfig(allocator, io, environ_map) catch |err| {
        handleConfigError(err, io, stderr);
        std.process.exit(1);
    };
    defer cfg.deinit();

    // Team selection logic: explicit name > default > single-team auto-select > error
    const selected_team_name = blk: {
        if (args.team_name) |team_name| {
            if (!cfg.teams.teams.contains(team_name)) {
                var buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "Team '{s}' not found in config\n", .{team_name}) catch "Team not found\n";
                stderr.writeStreamingAll(io, msg) catch {};
                std.process.exit(1);
            }
            break :blk team_name;
        }

        if (cfg.teams.default) |default_team| {
            break :blk default_team;
        }

        const team_count = cfg.teams.teams.count();
        if (team_count == 0) {
            stderr.writeStreamingAll(io, "No teams configured in config file\n") catch {};
            std.process.exit(1);
        } else if (team_count == 1) {
            var it = cfg.teams.teams.iterator();
            if (it.next()) |entry| {
                break :blk entry.key_ptr.*;
            }
            unreachable;
        }

        stderr.writeStreamingAll(io, "Multiple teams configured. Specify team name or set default in config.\n") catch {};
        stderr.writeStreamingAll(io, "Available teams: ") catch {};
        var it = cfg.teams.teams.iterator();
        var first = true;
        while (it.next()) |entry| {
            if (!first) {
                stderr.writeStreamingAll(io, ", ") catch {};
            }
            stderr.writeStreamingAll(io, entry.key_ptr.*) catch {};
            first = false;
        }
        stderr.writeStreamingAll(io, "\n") catch {};
        std.process.exit(1);
    };

    const team_config = cfg.teams.teams.get(selected_team_name) orelse {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Team '{s}' not found in config\n", .{selected_team_name}) catch "Team not found\n";
        stderr.writeStreamingAll(io, msg) catch {};
        std.process.exit(1);
    };

    var client = github.Client.init(allocator, io, cfg.auth_token);
    defer client.deinit();

    const effective_since = args.since orelse team_config.since;
    const effective_until = args.until orelse team_config.until;

    var all_prs: std.ArrayListUnmanaged(github.PullRequest) = .empty;
    defer {
        for (all_prs.items) |*pr| {
            pr.deinit(allocator);
        }
        all_prs.deinit(allocator);
    }

    for (team_config.orgs) |org| {
        if (args.org) |org_filter| {
            if (!std.mem.eql(u8, org, org_filter)) {
                continue;
            }
        }

        const prs = github.fetchTeamPRs(&client, org, team_config.members, args.member_filter, effective_since, effective_until) catch |err| {
            handleGitHubError(err, io, stderr);
            std.process.exit(1);
        };
        defer allocator.free(prs);

        for (prs) |pr| {
            try all_prs.append(allocator, pr);
        }
    }

    var output_buf: [65536]u8 = undefined;
    var w = stdout.writer(io, &output_buf);

    if (args.json) {
        try formatter.formatJsonOutput(&w.interface, all_prs.items);
    } else {
        const current_time = std.Io.Timestamp.now(io, .real).toSeconds();
        try formatter.formatTeamOutput(allocator, &w.interface, all_prs.items, current_time, io, environ_map);
    }
    try w.flush();
}

fn runMergedCommand(
    allocator: std.mem.Allocator,
    io: std.Io,
    environ_map: *std.process.Environ.Map,
    stdout: std.Io.File,
    stderr: std.Io.File,
    args: cli.MergedArgs,
) !void {
    var cfg = config.loadConfig(allocator, io, environ_map) catch |err| {
        handleConfigError(err, io, stderr);
        std.process.exit(1);
    };
    defer cfg.deinit();

    var client = github.Client.init(allocator, io, cfg.auth_token);
    defer client.deinit();

    const user = github.getAuthenticatedUser(&client) catch |err| {
        handleGitHubError(err, io, stderr);
        std.process.exit(1);
    };
    defer allocator.free(user);

    const days_to_use = args.days orelse 7;
    const since_date = if (args.since) |since|
        since
    else blk: {
        const date = time.getDateDaysAgo(allocator, days_to_use, io) catch {
            stderr.writeStreamingAll(io, "Failed to calculate date range\n") catch {};
            std.process.exit(1);
        };
        break :blk date;
    };
    defer {
        if (args.since == null) {
            allocator.free(since_date);
        }
    }

    const prs = github.fetchMergedPRs(&client, cfg.mine_orgs, args.org_filter, since_date, args.until) catch |err| {
        handleGitHubError(err, io, stderr);
        std.process.exit(1);
    };
    defer {
        for (prs) |*pr| {
            pr.deinit(allocator);
        }
        allocator.free(prs);
    }

    var output_buf: [65536]u8 = undefined;
    var w = stdout.writer(io, &output_buf);

    if (args.json) {
        try formatter.formatJsonOutput(&w.interface, prs);
    } else {
        try formatter.formatMergedUrlOutput(&w.interface, prs, days_to_use);
    }
    try w.flush();
}

fn handleConfigError(err: anyerror, io: std.Io, stderr: std.Io.File) void {
    switch (err) {
        error.ConfigNotFound => {},
        error.InvalidJson => {
            stderr.writeStreamingAll(io, "Invalid config: JSON parse error\n") catch {};
        },
        error.MissingMineOrgs => {
            stderr.writeStreamingAll(io, "Config error: mine.orgs must contain at least one org\n") catch {};
        },
        error.EmptyMineOrgs => {
            stderr.writeStreamingAll(io, "Config error: mine.orgs must contain at least one org\n") catch {};
        },
        error.EmptyOrgName => {
            stderr.writeStreamingAll(io, "Config error: mine.orgs contains empty org name\n") catch {};
        },
        error.EmptyTeamMembers => {
            stderr.writeStreamingAll(io, "Config error: team has no members listed\n") catch {};
        },
        error.EmptyTeamOrgs => {
            stderr.writeStreamingAll(io, "Config error: team has empty orgs array\n") catch {};
        },
        error.MissingTeamOrgs => {
            stderr.writeStreamingAll(io, "Config error: team must have 'orgs' field\n") catch {};
        },
        error.InvalidDefaultTeam => {
            stderr.writeStreamingAll(io, "Config error: 'default' references non-existent team\n") catch {};
        },
        error.NoDefaultTeam => {
            stderr.writeStreamingAll(io, "Config error: multiple teams configured but no default specified\n") catch {};
        },
        error.InvalidDateFormat => {
            stderr.writeStreamingAll(io, "Config error: Invalid date format. Use YYYY-MM-DD format.\n") catch {};
        },
        error.GhNotInstalled => {},
        error.NotAuthenticated => {},
        else => {
            stderr.writeStreamingAll(io, "Failed to load config\n") catch {};
        },
    }
}

fn handleGitHubError(err: anyerror, io: std.Io, stderr: std.Io.File) void {
    switch (err) {
        error.AuthError => {
            stderr.writeStreamingAll(io, "Authentication failed. Your token may have expired. Run `gh auth login`.\n") catch {};
        },
        error.RateLimitExceeded => {
            stderr.writeStreamingAll(io, "GitHub API rate limit exceeded. Try again later.\n") catch {};
        },
        error.NetworkError => {
            stderr.writeStreamingAll(io, "Failed to reach GitHub API. Check your network connection.\n") catch {};
        },
        error.ParseError => {
            stderr.writeStreamingAll(io, "Failed to parse GitHub API response.\n") catch {};
        },
        error.GhCommandFailed => {
            stderr.writeStreamingAll(io, "GitHub CLI command failed.\n") catch {};
        },
        else => {
            stderr.writeStreamingAll(io, "GitHub API error\n") catch {};
        },
    }
}
