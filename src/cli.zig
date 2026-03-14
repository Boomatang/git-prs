const std = @import("std");

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

pub const Command = union(enum) {
    mine: MineArgs,
    team: TeamArgs,
    help: void,
};

pub const ParseError = error{
    UnknownCommand,
    InvalidFlag,
    MissingFlagValue,
    InvalidLimitValue,
    InvalidDateValue,
};

/// Parse command line arguments.
/// Returns the parsed command or shows help message and returns .help
pub fn parseArgs(allocator: std.mem.Allocator, args: []const []const u8) ParseError!Command {
    _ = allocator;

    // No arguments or --help flag
    if (args.len == 0) {
        return .help;
    }

    // Check for --help flag
    if (std.mem.eql(u8, args[0], "--help") or std.mem.eql(u8, args[0], "-h")) {
        return .help;
    }

    const command_name = args[0];

    if (std.mem.eql(u8, command_name, "mine")) {
        return .{ .mine = try parseMineArgs(args[1..]) };
    } else if (std.mem.eql(u8, command_name, "team")) {
        return .{ .team = try parseTeamArgs(args[1..]) };
    } else {
        return error.UnknownCommand;
    }
}

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

fn parseMineArgs(args: []const []const u8) ParseError!MineArgs {
    var result = MineArgs{};
    var i: usize = 0;

    while (i < args.len) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--org")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            result.org_filter = args[i];
        } else if (std.mem.eql(u8, arg, "--limit")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            result.limit = std.fmt.parseInt(u32, args[i], 10) catch {
                return error.InvalidLimitValue;
            };
        } else if (std.mem.eql(u8, arg, "--json")) {
            result.json = true;
        } else if (std.mem.eql(u8, arg, "--since")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            const date = args[i];
            if (!isValidDateFormat(date)) {
                return error.InvalidDateValue;
            }
            result.since = date;
        } else if (std.mem.eql(u8, arg, "--until")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            const date = args[i];
            if (!isValidDateFormat(date)) {
                return error.InvalidDateValue;
            }
            result.until = date;
        } else {
            return error.InvalidFlag;
        }

        i += 1;
    }

    return result;
}

fn parseTeamArgs(args: []const []const u8) ParseError!TeamArgs {
    var result = TeamArgs{};
    var i: usize = 0;

    // Parse optional positional team name (first arg if it doesn't start with --)
    if (args.len > 0 and !std.mem.startsWith(u8, args[0], "--")) {
        result.team_name = args[0];
        i = 1;
    }

    while (i < args.len) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--org")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            result.org = args[i];
        } else if (std.mem.eql(u8, arg, "--member")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            result.member_filter = args[i];
        } else if (std.mem.eql(u8, arg, "--json")) {
            result.json = true;
        } else if (std.mem.eql(u8, arg, "--since")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            const date = args[i];
            if (!isValidDateFormat(date)) {
                return error.InvalidDateValue;
            }
            result.since = date;
        } else if (std.mem.eql(u8, arg, "--until")) {
            i += 1;
            if (i >= args.len) {
                return error.MissingFlagValue;
            }
            const date = args[i];
            if (!isValidDateFormat(date)) {
                return error.InvalidDateValue;
            }
            result.until = date;
        } else {
            return error.InvalidFlag;
        }

        i += 1;
    }

    return result;
}

/// Write usage information to the provided writer
pub fn printUsage(writer: anytype) !void {
    try writer.writeAll(
        \\git-prs - Manage GitHub Pull Requests
        \\
        \\USAGE:
        \\    git-prs <COMMAND> [OPTIONS]
        \\
        \\COMMANDS:
        \\    mine                   List PRs assigned to you
        \\    team [name]            List PRs for your team
        \\    --help, -h             Show this help message
        \\
        \\MINE OPTIONS:
        \\    --org <name>           Filter to specific org (optional)
        \\    --limit <n>            Max PRs to show (default: 50)
        \\    --since <YYYY-MM-DD>   Only PRs created on or after this date
        \\    --until <YYYY-MM-DD>   Only PRs created on or before this date
        \\    --json                 Output as JSON array
        \\
        \\TEAM OPTIONS:
        \\    [name]                 Team name (uses default or auto-selects if omitted)
        \\    --org <name>           Filter to specific org (optional)
        \\    --member <username>    Filter to specific team member (optional)
        \\    --since <YYYY-MM-DD>   Only PRs created on or after this date (overrides config)
        \\    --until <YYYY-MM-DD>   Only PRs created on or before this date (overrides config)
        \\    --json                 Output as JSON array
        \\
        \\EXAMPLES:
        \\    git-prs mine
        \\    git-prs mine --org kubernetes --limit 10
        \\    git-prs mine --since 2025-01-01
        \\    git-prs team
        \\    git-prs team release
        \\    git-prs team release --member alice
        \\    git-prs team traffic --since 2025-01-01 --until 2025-06-30
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
    try std.testing.expectError(error.MissingFlagValue, result);
}

test "missing --limit value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--limit" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.MissingFlagValue, result);
}

test "invalid limit value returns error" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{ "mine", "--limit", "not-a-number" };

    const result = parseArgs(allocator, &args);
    try std.testing.expectError(error.InvalidLimitValue, result);
}

test "printUsage writes help text" {
    var buffer: std.ArrayList(u8) = .{};
    defer buffer.deinit(std.testing.allocator);

    try printUsage(buffer.writer(std.testing.allocator));

    const output = buffer.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "git-prs") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "mine") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "team") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "--org") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "--limit") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "--member") != null);
}

test "-h flag returns help command" {
    const allocator = std.testing.allocator;
    const args = [_][]const u8{"-h"};

    const result = try parseArgs(allocator, &args);
    try std.testing.expectEqual(Command.help, std.meta.activeTag(result));
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
    try std.testing.expectError(error.MissingFlagValue, result);
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
    try std.testing.expectError(error.MissingFlagValue, result);
}
