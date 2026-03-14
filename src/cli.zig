const std = @import("std");

pub const MineArgs = struct {
    org_filter: ?[]const u8 = null, // --org value or null
    limit: u32 = 50, // --limit value, default 50
    json: bool = false, // --json flag for JSON output
};

pub const TeamArgs = struct {
    org: ?[]const u8 = null, // --org value (may be auto-selected if only one team configured)
    member_filter: ?[]const u8 = null, // --member value or null
    json: bool = false, // --json flag for JSON output
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
        \\    team                   List PRs for your team
        \\    --help, -h             Show this help message
        \\
        \\MINE OPTIONS:
        \\    --org <name>           Filter to specific org (optional)
        \\    --limit <n>            Max PRs to show (default: 50)
        \\    --json                 Output as JSON array
        \\
        \\TEAM OPTIONS:
        \\    --org <name>           Which org to check (auto-selected if only one configured)
        \\    --member <username>    Filter to specific team member (optional)
        \\    --json                 Output as JSON array
        \\
        \\EXAMPLES:
        \\    git-prs mine
        \\    git-prs mine --org kubernetes --limit 10
        \\    git-prs team --org my-company
        \\    git-prs team --org my-company --member alice
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
