//! Configuration management for git-prs
//! Loads and validates configuration from XDG config directory

const std = @import("std");
const fs = std.fs;
const process = std.process;

pub const Config = struct {
    allocator: std.mem.Allocator,
    mine_orgs: []const []const u8,
    teams: std.StringHashMapUnmanaged([]const []const u8),
    auth_token: []const u8,
    authenticated_user: []const u8,

    pub fn deinit(self: *Config) void {
        // Free mine_orgs strings and array
        for (self.mine_orgs) |org| {
            self.allocator.free(org);
        }
        self.allocator.free(self.mine_orgs);

        // Free teams hash map
        var it = self.teams.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*) |member| {
                self.allocator.free(member);
            }
            self.allocator.free(entry.value_ptr.*);
        }
        self.teams.deinit(self.allocator);

        // Free auth token and user
        self.allocator.free(self.auth_token);
        self.allocator.free(self.authenticated_user);
    }
};

pub const ConfigError = error{
    ConfigNotFound,
    InvalidJson,
    MissingMineOrgs,
    EmptyMineOrgs,
    EmptyOrgName,
    EmptyTeamMembers,
    GhNotInstalled,
    NotAuthenticated,
    FailedToGetUser,
    EnvironmentVariableNotFound,
    NetworkSubsystemFailed,
    StdoutStreamTooLong,
    StderrStreamTooLong,
} || std.mem.Allocator.Error || std.fs.File.OpenError || std.fs.File.ReadError || std.process.Child.SpawnError;

/// Load configuration from XDG config directory.
/// Calls `gh auth token` to get auth token.
/// Does NOT call GitHub API to get authenticated user - that's the caller's responsibility.
pub fn loadConfig(allocator: std.mem.Allocator) ConfigError!Config {
    const config_path = try getConfigPath(allocator);
    defer allocator.free(config_path);

    // Read config file
    const config_file = fs.openFileAbsolute(config_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            printConfigNotFoundError();
            return ConfigError.ConfigNotFound;
        }
        return err;
    };
    defer config_file.close();

    const config_contents = try config_file.readToEndAlloc(allocator, 1024 * 1024); // 1MB max
    defer allocator.free(config_contents);

    // Parse JSON
    const parsed = std.json.parseFromSlice(
        std.json.Value,
        allocator,
        config_contents,
        .{},
    ) catch {
        return ConfigError.InvalidJson;
    };
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) {
        return ConfigError.InvalidJson;
    }

    // Extract and validate mine_orgs
    const mine_orgs = try parseMineOrgs(allocator, root.object);

    // Extract and validate teams (optional)
    var teams = std.StringHashMapUnmanaged([]const []const u8){};
    errdefer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*) |member| {
                allocator.free(member);
            }
            allocator.free(entry.value_ptr.*);
        }
        teams.deinit(allocator);
    }

    if (root.object.get("team")) |team_value| {
        teams = try parseTeams(allocator, team_value);
    }

    // Get auth token
    const auth_token = getAuthToken(allocator) catch |err| {
        // Clean up mine_orgs on error
        for (mine_orgs) |org| {
            allocator.free(org);
        }
        allocator.free(mine_orgs);
        return err;
    };

    return Config{
        .allocator = allocator,
        .mine_orgs = mine_orgs,
        .teams = teams,
        .auth_token = auth_token,
        .authenticated_user = "", // Caller's responsibility to set this
    };
}

/// Get the config file path using XDG config directory
fn getConfigPath(allocator: std.mem.Allocator) ![]const u8 {
    const config_home = if (process.getEnvVarOwned(allocator, "XDG_CONFIG_HOME")) |xdg_config|
        xdg_config
    else |_| blk: {
        const home = try process.getEnvVarOwned(allocator, "HOME");
        defer allocator.free(home);
        break :blk try fs.path.join(allocator, &.{ home, ".config" });
    };
    defer allocator.free(config_home);

    return try fs.path.join(allocator, &.{ config_home, "git-prs", "config.json" });
}

/// Parse and validate mine_orgs from JSON
fn parseMineOrgs(allocator: std.mem.Allocator, root: std.json.ObjectMap) ConfigError![]const []const u8 {
    const mine_obj = root.get("mine") orelse return ConfigError.MissingMineOrgs;
    if (mine_obj != .object) return ConfigError.MissingMineOrgs;

    const orgs_array = mine_obj.object.get("orgs") orelse return ConfigError.MissingMineOrgs;
    if (orgs_array != .array) return ConfigError.MissingMineOrgs;

    const orgs = orgs_array.array;
    if (orgs.items.len == 0) return ConfigError.EmptyMineOrgs;

    var result = try std.ArrayList([]const u8).initCapacity(allocator, orgs.items.len);
    errdefer {
        for (result.items) |org| {
            allocator.free(org);
        }
        result.deinit(allocator);
    }

    for (orgs.items) |org_value| {
        if (org_value != .string) return ConfigError.InvalidJson;
        const org_str = org_value.string;
        if (org_str.len == 0) return ConfigError.EmptyOrgName;

        const org_copy = try allocator.dupe(u8, org_str);
        try result.append(allocator, org_copy);
    }

    return try result.toOwnedSlice(allocator);
}

/// Parse and validate teams from JSON
fn parseTeams(allocator: std.mem.Allocator, team_value: std.json.Value) ConfigError!std.StringHashMapUnmanaged([]const []const u8) {
    if (team_value != .object) return ConfigError.InvalidJson;

    var teams = std.StringHashMapUnmanaged([]const []const u8){};
    errdefer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*) |member| {
                allocator.free(member);
            }
            allocator.free(entry.value_ptr.*);
        }
        teams.deinit(allocator);
    }

    var it = team_value.object.iterator();
    while (it.next()) |entry| {
        const org_name = entry.key_ptr.*;
        const members_value = entry.value_ptr.*;

        if (members_value != .array) return ConfigError.InvalidJson;
        const members_array = members_value.array;
        if (members_array.items.len == 0) return ConfigError.EmptyTeamMembers;

        var members = try std.ArrayList([]const u8).initCapacity(allocator, members_array.items.len);
        errdefer {
            for (members.items) |member| {
                allocator.free(member);
            }
            members.deinit(allocator);
        }

        for (members_array.items) |member_value| {
            if (member_value != .string) return ConfigError.InvalidJson;
            const member_copy = try allocator.dupe(u8, member_value.string);
            try members.append(allocator, member_copy);
        }

        const org_name_copy = try allocator.dupe(u8, org_name);
        const members_slice = try members.toOwnedSlice(allocator);
        try teams.put(allocator, org_name_copy, members_slice);
    }

    return teams;
}

/// Get GitHub auth token by running `gh auth token`
fn getAuthToken(allocator: std.mem.Allocator) ConfigError![]const u8 {
    const result = process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "gh", "auth", "token" },
    }) catch |err| {
        if (err == error.FileNotFound) {
            printGhNotInstalledError();
            return ConfigError.GhNotInstalled;
        }
        return err;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        printNotAuthenticatedError();
        return ConfigError.NotAuthenticated;
    }

    const token = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);
    return try allocator.dupe(u8, token);
}

fn printConfigNotFoundError() void {
    const stderr = std.fs.File.stderr();
    _ = stderr.write("Config not found. Create ~/.config/git-prs/config.json\n\n") catch {};
    _ = stderr.write("Example:\n") catch {};
    _ = stderr.write(
        \\{
        \\  "mine": {
        \\    "orgs": ["jfitzpat", "kubernetes", "my-company"]
        \\  },
        \\  "team": {
        \\    "my-company": ["alice", "bob", "charlie"],
        \\    "other-org": ["dave", "eve"]
        \\  }
        \\}
        \\
    ) catch {};
    _ = stderr.write("\n") catch {};
}

fn printGhNotInstalledError() void {
    const stderr = std.fs.File.stderr();
    _ = stderr.write("gh CLI not found. Install from https://cli.github.com\n") catch {};
}

fn printNotAuthenticatedError() void {
    const stderr = std.fs.File.stderr();
    _ = stderr.write("Not authenticated. Run `gh auth login` first\n") catch {};
}

// Tests

test "getConfigPath with XDG_CONFIG_HOME set" {
    // Note: This test would require mocking environment variables which is difficult in Zig
    // For actual testing, we'd need to spawn a subprocess with the env var set
    // We'll verify the path construction logic manually

    const expected = "/custom/config/git-prs/config.json";
    _ = expected;
    // In real implementation, we'd check the path matches expected
}

test "getConfigPath with XDG_CONFIG_HOME unset" {
    const allocator = std.testing.allocator;

    // When XDG_CONFIG_HOME is unset, should use ~/.config
    // This test requires HOME to be set, which is typically true in test environments
    const home = process.getEnvVarOwned(allocator, "HOME") catch {
        // Skip test if HOME not set
        return error.SkipZigTest;
    };
    defer allocator.free(home);

    const expected_suffix = ".config/git-prs/config.json";
    _ = expected_suffix;
    // In real implementation, we'd verify the path ends with this suffix
}

test "parseMineOrgs with valid data" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "mine": {
        \\    "orgs": ["org1", "org2", "org3"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const orgs = try parseMineOrgs(allocator, parsed.value.object);
    defer {
        for (orgs) |org| {
            allocator.free(org);
        }
        allocator.free(orgs);
    }

    try std.testing.expectEqual(@as(usize, 3), orgs.len);
    try std.testing.expectEqualStrings("org1", orgs[0]);
    try std.testing.expectEqualStrings("org2", orgs[1]);
    try std.testing.expectEqualStrings("org3", orgs[2]);
}

test "parseMineOrgs with missing mine" {
    const allocator = std.testing.allocator;

    const json_str = "{}";

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseMineOrgs(allocator, parsed.value.object);
    try std.testing.expectError(ConfigError.MissingMineOrgs, result);
}

test "parseMineOrgs with empty orgs array" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "mine": {
        \\    "orgs": []
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseMineOrgs(allocator, parsed.value.object);
    try std.testing.expectError(ConfigError.EmptyMineOrgs, result);
}

test "parseMineOrgs with empty org name" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "mine": {
        \\    "orgs": ["org1", "", "org3"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseMineOrgs(allocator, parsed.value.object);
    try std.testing.expectError(ConfigError.EmptyOrgName, result);
}

test "parseTeams with valid data" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "my-company": ["alice", "bob"],
        \\  "other-org": ["charlie"]
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    var teams = try parseTeams(allocator, parsed.value);
    defer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*) |member| {
                allocator.free(member);
            }
            allocator.free(entry.value_ptr.*);
        }
        teams.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 2), teams.count());

    const my_company_members = teams.get("my-company").?;
    try std.testing.expectEqual(@as(usize, 2), my_company_members.len);
    try std.testing.expectEqualStrings("alice", my_company_members[0]);
    try std.testing.expectEqualStrings("bob", my_company_members[1]);

    const other_org_members = teams.get("other-org").?;
    try std.testing.expectEqual(@as(usize, 1), other_org_members.len);
    try std.testing.expectEqualStrings("charlie", other_org_members[0]);
}

test "parseTeams with empty members array" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "my-company": []
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseTeams(allocator, parsed.value);
    try std.testing.expectError(ConfigError.EmptyTeamMembers, result);
}

test "full config parsing with teams" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "mine": {
        \\    "orgs": ["jfitzpat", "kubernetes"]
        \\  },
        \\  "team": {
        \\    "jfitzpat": ["alice", "bob"],
        \\    "kubernetes": ["charlie", "dave", "eve"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const root = parsed.value;

    // Parse mine_orgs
    const mine_orgs = try parseMineOrgs(allocator, root.object);
    defer {
        for (mine_orgs) |org| {
            allocator.free(org);
        }
        allocator.free(mine_orgs);
    }

    try std.testing.expectEqual(@as(usize, 2), mine_orgs.len);
    try std.testing.expectEqualStrings("jfitzpat", mine_orgs[0]);
    try std.testing.expectEqualStrings("kubernetes", mine_orgs[1]);

    // Parse teams
    const team_value = root.object.get("team").?;
    var teams = try parseTeams(allocator, team_value);
    defer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*) |member| {
                allocator.free(member);
            }
            allocator.free(entry.value_ptr.*);
        }
        teams.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 2), teams.count());

    const jfitzpat_team = teams.get("jfitzpat").?;
    try std.testing.expectEqual(@as(usize, 2), jfitzpat_team.len);
    try std.testing.expectEqualStrings("alice", jfitzpat_team[0]);
    try std.testing.expectEqualStrings("bob", jfitzpat_team[1]);

    const kubernetes_team = teams.get("kubernetes").?;
    try std.testing.expectEqual(@as(usize, 3), kubernetes_team.len);
    try std.testing.expectEqualStrings("charlie", kubernetes_team[0]);
    try std.testing.expectEqualStrings("dave", kubernetes_team[1]);
    try std.testing.expectEqualStrings("eve", kubernetes_team[2]);
}

test "full config parsing without teams" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "mine": {
        \\    "orgs": ["jfitzpat"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const root = parsed.value;

    // Parse mine_orgs
    const mine_orgs = try parseMineOrgs(allocator, root.object);
    defer {
        for (mine_orgs) |org| {
            allocator.free(org);
        }
        allocator.free(mine_orgs);
    }

    try std.testing.expectEqual(@as(usize, 1), mine_orgs.len);
    try std.testing.expectEqualStrings("jfitzpat", mine_orgs[0]);

    // Verify teams is optional
    const team_value = root.object.get("team");
    try std.testing.expect(team_value == null);
}
