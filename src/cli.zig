const std = @import("std");
const clap = @import("clap");

pub const MineArgs = struct {
    org_filter: ?[]const u8 = null, // --org value or null
    limit: u32 = 50, // --limit value, default 50
    json: bool = false, // --json flag for JSON output
    since: ?[]const u8 = null, // --since YYYY-MM-DD
    until: ?[]const u8 = null, // --until YYYY-MM-DD
};

pub const TeamArgs = struct {
    team_name: ?[]const u8 = null, // positional team name argument
    org: ?[]const u8 = null, // --org value (may be auto-selected if only one team configured)
    member_filter: ?[]const u8 = null, // --member value or null
    json: bool = false, // --json flag for JSON output
    since: ?[]const u8 = null, // --since YYYY-MM-DD
    until: ?[]const u8 = null, // --until YYYY-MM-DD
};

pub const MergedArgs = struct {
    days: ?u32 = null, // --days N for last N days (default 7 if no date flags)
    org_filter: ?[]const u8 = null, // --org value or null
    json: bool = false, // --json flag for JSON output
    since: ?[]const u8 = null, // --since YYYY-MM-DD (mutually exclusive with --days)
    until: ?[]const u8 = null, // --until YYYY-MM-DD (used with --since)
};

pub const VersionArgs = struct {
    json: bool = false,
};

pub const Command = union(enum) {
    mine: MineArgs,
    team: TeamArgs,
    merged: MergedArgs,
    help: void,
    version: VersionArgs,
};

pub const ParseError = error{
    UnknownCommand,
    InvalidFlag,
    MissingFlagValue,
    InvalidLimitValue,
    InvalidDateValue,
    DaysWithDateRange,
    InvalidDaysValue,
};

/// Validate date format is YYYY-MM-DD
fn isValidDateFormat(date_str: []const u8) bool {
    if (date_str.len != 10) return false;
    if (date_str[4] != '-' or date_str[7] != '-') return false;
    _ = std.fmt.parseInt(u16, date_str[0..4], 10) catch return false;
    const month = std.fmt.parseInt(u8, date_str[5..7], 10) catch return false;
    const day = std.fmt.parseInt(u8, date_str[8..10], 10) catch return false;
    if (month < 1 or month > 12) return false;
    if (day < 1 or day > 31) return false;
    return true;
}

// Parameter definitions for each command using clap.parseParamsComptime
const mine_params = clap.parseParamsComptime(
    \\-h, --help             Show help for mine command
    \\    --org <str>        Filter to specific org
    \\-l, --limit <u32>      Max PRs to show (default: 50)
    \\    --since <str>      Only PRs created on or after this date (YYYY-MM-DD)
    \\    --until <str>      Only PRs created on or before this date (YYYY-MM-DD)
    \\    --json             Output as JSON array
    \\    --version          Show version information
    \\
);

const team_params = clap.parseParamsComptime(
    \\-h, --help             Show help for team command
    \\    --org <str>        Filter to specific org
    \\    --member <str>     Filter to specific team member
    \\    --since <str>      Only PRs created on or after this date (YYYY-MM-DD)
    \\    --until <str>      Only PRs created on or before this date (YYYY-MM-DD)
    \\    --json             Output as JSON array
    \\    --version          Show version information
    \\<str>...
    \\
);

const merged_params = clap.parseParamsComptime(
    \\-h, --help             Show help for merged command
    \\    --days <u32>       Show PRs merged in last N days
    \\    --org <str>        Filter to specific org
    \\    --since <str>      Only PRs merged on or after this date (YYYY-MM-DD)
    \\    --until <str>      Only PRs merged on or before this date (YYYY-MM-DD)
    \\    --json             Output as JSON array
    \\    --version          Show version information
    \\
);

/// Parse command line arguments using clap.
/// Returns the parsed command or shows help message and returns .help
pub fn parseArgs(allocator: std.mem.Allocator, args: []const []const u8) ParseError!Command {
    // No arguments - show help
    if (args.len == 0) {
        return .help;
    }

    // Check for --version flag anywhere in args (before subcommand parsing)
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--version")) {
            // Check for --json flag
            for (args) |a| {
                if (std.mem.eql(u8, a, "--json")) {
                    return .{ .version = .{ .json = true } };
                }
            }
            return .{ .version = .{ .json = false } };
        }
    }

    // Check for --help or -h flag at first position
    if (std.mem.eql(u8, args[0], "--help") or std.mem.eql(u8, args[0], "-h")) {
        return .help;
    }

    const command_name = args[0];
    const sub_args = args[1..];

    if (std.mem.eql(u8, command_name, "mine")) {
        return parseMineCommand(allocator, sub_args);
    } else if (std.mem.eql(u8, command_name, "team")) {
        return parseTeamCommand(allocator, sub_args);
    } else if (std.mem.eql(u8, command_name, "merged")) {
        return parseMergedCommand(allocator, sub_args);
    } else {
        return error.UnknownCommand;
    }
}

fn parseMineCommand(allocator: std.mem.Allocator, args: []const []const u8) ParseError!Command {
    var iter = clap.args.SliceIterator{ .args = args };
    var res = clap.parseEx(clap.Help, &mine_params, clap.parsers.default, &iter, .{
        .allocator = allocator,
    }) catch {
        return error.InvalidFlag;
    };
    defer res.deinit();

    // Check for help flag
    if (res.args.help != 0) {
        return .help;
    }

    // Check for version flag
    if (res.args.version != 0) {
        return .{ .version = .{ .json = res.args.json != 0 } };
    }

    // Validate dates
    if (res.args.since) |since| {
        if (!isValidDateFormat(since)) {
            return error.InvalidDateValue;
        }
    }
    if (res.args.until) |until| {
        if (!isValidDateFormat(until)) {
            return error.InvalidDateValue;
        }
    }

    return .{ .mine = .{
        .org_filter = res.args.org,
        .limit = res.args.limit orelse 50,
        .json = res.args.json != 0,
        .since = res.args.since,
        .until = res.args.until,
    } };
}

fn parseTeamCommand(allocator: std.mem.Allocator, args: []const []const u8) ParseError!Command {
    var iter = clap.args.SliceIterator{ .args = args };
    var res = clap.parseEx(clap.Help, &team_params, clap.parsers.default, &iter, .{
        .allocator = allocator,
    }) catch {
        return error.InvalidFlag;
    };
    defer res.deinit();

    // Check for help flag
    if (res.args.help != 0) {
        return .help;
    }

    // Check for version flag
    if (res.args.version != 0) {
        return .{ .version = .{ .json = res.args.json != 0 } };
    }

    // Validate dates
    if (res.args.since) |since| {
        if (!isValidDateFormat(since)) {
            return error.InvalidDateValue;
        }
    }
    if (res.args.until) |until| {
        if (!isValidDateFormat(until)) {
            return error.InvalidDateValue;
        }
    }

    // Get team name from positional arguments (res.positionals[0] is []const []const u8)
    const positional_args = res.positionals[0];
    const team_name = if (positional_args.len > 0) positional_args[0] else null;

    return .{ .team = .{
        .team_name = team_name,
        .org = res.args.org,
        .member_filter = res.args.member,
        .json = res.args.json != 0,
        .since = res.args.since,
        .until = res.args.until,
    } };
}

fn parseMergedCommand(allocator: std.mem.Allocator, args: []const []const u8) ParseError!Command {
    var iter = clap.args.SliceIterator{ .args = args };
    var res = clap.parseEx(clap.Help, &merged_params, clap.parsers.default, &iter, .{
        .allocator = allocator,
    }) catch {
        return error.InvalidFlag;
    };
    defer res.deinit();

    // Check for help flag
    if (res.args.help != 0) {
        return .help;
    }

    // Check for version flag
    if (res.args.version != 0) {
        return .{ .version = .{ .json = res.args.json != 0 } };
    }

    // Validate dates
    if (res.args.since) |since| {
        if (!isValidDateFormat(since)) {
            return error.InvalidDateValue;
        }
    }
    if (res.args.until) |until| {
        if (!isValidDateFormat(until)) {
            return error.InvalidDateValue;
        }
    }

    // Validate: --days is mutually exclusive with --since or --until
    if (res.args.days != null and (res.args.since != null or res.args.until != null)) {
        return error.DaysWithDateRange;
    }

    return .{ .merged = .{
        .days = res.args.days,
        .org_filter = res.args.org,
        .json = res.args.json != 0,
        .since = res.args.since,
        .until = res.args.until,
    } };
}

/// Write usage information to the provided writer (using clap's help generation)
pub fn printUsage(writer: anytype) !void {
    try writer.writeAll(
        \\git-prs - Manage GitHub Pull Requests
        \\
        \\Usage: git-prs <command> [options]
        \\
        \\Commands:
        \\  mine      List PRs assigned to you
        \\  team      List PRs for your team
        \\  merged    List merged PRs by you
        \\
        \\General Options:
        \\  -h, --help     Show this help message
        \\      --version  Show version information
        \\
        \\Run 'git-prs <command> --help' for more information on a command.
        \\
    );
}

/// Print help for the mine command
pub fn printMineHelp(writer: anytype) !void {
    try writer.writeAll(
        \\git-prs mine - List PRs assigned to you
        \\
        \\Usage: git-prs mine [options]
        \\
        \\Options:
        \\
    );
    clap.help(writer, clap.Help, &mine_params, .{}) catch {};
    try writer.writeAll(
        \\
        \\Examples:
        \\  git-prs mine
        \\  git-prs mine --org kubernetes --limit 10
        \\  git-prs mine --since 2025-01-01
        \\
    );
}

/// Print help for the team command
pub fn printTeamHelp(writer: anytype) !void {
    try writer.writeAll(
        \\git-prs team - List PRs for your team
        \\
        \\Usage: git-prs team [name] [options]
        \\
        \\Arguments:
        \\  [name]    Team name (uses default or auto-selects if omitted)
        \\
        \\Options:
        \\
    );
    clap.help(writer, clap.Help, &team_params, .{}) catch {};
    try writer.writeAll(
        \\
        \\Examples:
        \\  git-prs team
        \\  git-prs team release
        \\  git-prs team release --member alice
        \\  git-prs team traffic --since 2025-01-01 --until 2025-06-30
        \\
    );
}

/// Print help for the merged command
pub fn printMergedHelp(writer: anytype) !void {
    try writer.writeAll(
        \\git-prs merged - List merged PRs by you
        \\
        \\Usage: git-prs merged [options]
        \\
        \\Options:
        \\
    );
    clap.help(writer, clap.Help, &merged_params, .{}) catch {};
    try writer.writeAll(
        \\
        \\Note: --days is mutually exclusive with --since/--until
        \\
        \\Examples:
        \\  git-prs merged
        \\  git-prs merged --days 14
        \\  git-prs merged --since 2025-01-01 --until 2025-06-30
        \\
    );
}

// Tests
test "mine with no flags" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"mine"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?[]const u8, null), result.mine.org_filter);
    try std.testing.expectEqual(@as(u32, 50), result.mine.limit);
}

test "mine with --org kubernetes" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--org", "kubernetes" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("kubernetes", result.mine.org_filter.?);
    try std.testing.expectEqual(@as(u32, 50), result.mine.limit);
}

test "mine with --limit 10" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--limit", "10" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?[]const u8, null), result.mine.org_filter);
    try std.testing.expectEqual(@as(u32, 10), result.mine.limit);
}

test "mine with --org kubernetes --limit 25" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--org", "kubernetes", "--limit", "25" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("kubernetes", result.mine.org_filter.?);
    try std.testing.expectEqual(@as(u32, 25), result.mine.limit);
}

test "team with --org my-company" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--org", "my-company" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("my-company", result.team.org.?);
    try std.testing.expectEqual(@as(?[]const u8, null), result.team.member_filter);
}

test "team with --org my-company --member alice" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--org", "my-company", "--member", "alice" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("my-company", result.team.org.?);
    try std.testing.expectEqualStrings("alice", result.team.member_filter.?);
}

test "--help returns help command" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"--help"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.help, std.meta.activeTag(result));
}

test "no arguments returns help command" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.help, std.meta.activeTag(result));
}

test "unknown command returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"invalid"};

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.UnknownCommand, result);
}

test "invalid flag for mine returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--invalid" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "missing --org value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--org" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "missing --limit value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--limit" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "invalid limit value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--limit", "not-a-number" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "printUsage writes help text" {
    var buffer: std.ArrayList(u8) = .{};
    defer buffer.deinit(std.testing.allocator);

    try printUsage(buffer.writer(std.testing.allocator));

    const output = buffer.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "git-prs") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "mine") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "team") != null);
}

test "-h flag returns help command" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"-h"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.help, std.meta.activeTag(result));
}

test "--version flag returns version command" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"--version"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.version, std.meta.activeTag(result));
    try std.testing.expect(!result.version.json);
}

test "team with no flags" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"team"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?[]const u8, null), result.team.org);
    try std.testing.expectEqual(@as(?[]const u8, null), result.team.member_filter);
}

test "invalid flag for team returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--invalid" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "missing --member value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--member" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "mine with --json flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expect(result.mine.json);
}

test "mine with --org and --json flags" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--org", "kubernetes", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("kubernetes", result.mine.org_filter.?);
    try std.testing.expect(result.mine.json);
}

test "team with --json flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expect(result.team.json);
}

test "team with --org and --json flags" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--org", "my-company", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("my-company", result.team.org.?);
    try std.testing.expect(result.team.json);
}

test "mine with --since flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--since", "2025-01-01" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("2025-01-01", result.mine.since.?);
    try std.testing.expectEqual(@as(?[]const u8, null), result.mine.until);
}

test "mine with --until flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--until", "2025-12-31" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?[]const u8, null), result.mine.since);
    try std.testing.expectEqualStrings("2025-12-31", result.mine.until.?);
}

test "mine with both --since and --until" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--since", "2025-01-01", "--until", "2025-06-30" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.mine, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("2025-01-01", result.mine.since.?);
    try std.testing.expectEqualStrings("2025-06-30", result.mine.until.?);
}

test "team with --since flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--since", "2025-01-01" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("2025-01-01", result.team.since.?);
    try std.testing.expectEqual(@as(?[]const u8, null), result.team.until);
}

test "team with --until flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "team", "--until", "2025-12-31" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.team, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?[]const u8, null), result.team.since);
    try std.testing.expectEqualStrings("2025-12-31", result.team.until.?);
}

test "invalid date format returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--since", "2025/01/01" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidDateValue, result);
}

test "missing date value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--since" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "merged with no flags" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"merged"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.merged, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?u32, null), result.merged.days);
    try std.testing.expectEqual(@as(?[]const u8, null), result.merged.org_filter);
    try std.testing.expect(!result.merged.json);
}

test "merged with --days flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--days", "14" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.merged, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?u32, 14), result.merged.days);
}

test "merged with --org flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--org", "kubernetes" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.merged, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("kubernetes", result.merged.org_filter.?);
}

test "merged with --json flag" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.merged, std.meta.activeTag(result));
    try std.testing.expect(result.merged.json);
}

test "merged with --since and --until" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--since", "2025-01-01", "--until", "2025-06-30" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.merged, std.meta.activeTag(result));
    try std.testing.expectEqualStrings("2025-01-01", result.merged.since.?);
    try std.testing.expectEqualStrings("2025-06-30", result.merged.until.?);
}

test "merged with --days and --since returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--days", "7", "--since", "2025-01-01" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.DaysWithDateRange, result);
}

test "merged with --days and --until returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--days", "7", "--until", "2025-01-01" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.DaysWithDateRange, result);
}

test "merged with invalid --days value" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--days", "not-a-number" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidFlag, result);
}

test "merged with all flags" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "merged", "--days", "30", "--org", "kubernetes", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.merged, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(?u32, 30), result.merged.days);
    try std.testing.expectEqualStrings("kubernetes", result.merged.org_filter.?);
    try std.testing.expect(result.merged.json);
}

test "--version --json returns version with json=true" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "--version", "--json" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.version, std.meta.activeTag(result));
    try std.testing.expect(result.version.json);
}

test "--json --version returns version with json=true" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "--json", "--version" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.version, std.meta.activeTag(result));
    try std.testing.expect(result.version.json);
}

test "mine --version returns version command (not mine)" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--version" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.version, std.meta.activeTag(result));
    try std.testing.expect(!result.version.json);
}

test "mine --json --version returns version with json=true" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--json", "--version" };

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.version, std.meta.activeTag(result));
    try std.testing.expect(result.version.json);
}
