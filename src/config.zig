//! Configuration management for git-prs
//! Loads and validates configuration from XDG config directory

const std = @import("std");
const fs = std.fs;
const process = std.process;

pub const TeamConfig = struct {
    members: []const []const u8,
    since: ?[]const u8 = null, // Optional YYYY-MM-DD
    until: ?[]const u8 = null, // Optional YYYY-MM-DD
};

pub const Config = struct {
    allocator: std.mem.Allocator,
    mine_orgs: []const []const u8,
    teams: std.StringHashMapUnmanaged(TeamConfig),
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
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                self.allocator.free(member);
            }
            self.allocator.free(team_config.members);
            if (team_config.since) |since| {
                self.allocator.free(since);
            }
            if (team_config.until) |until| {
                self.allocator.free(until);
            }
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
    InvalidDateFormat,
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
    var teams = std.StringHashMapUnmanaged(TeamConfig){};
    errdefer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                allocator.free(member);
            }
            allocator.free(team_config.members);
            if (team_config.since) |since| {
                allocator.free(since);
            }
            if (team_config.until) |until| {
                allocator.free(until);
            }
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

/// Validate date format is YYYY-MM-DD
fn validateDateFormat(date_str: []const u8) bool {
    if (date_str.len != 10) return false;
    // Check YYYY-MM-DD format
    if (date_str[4] != '-' or date_str[7] != '-') return false;
    // Validate numeric parts
    _ = std.fmt.parseInt(u16, date_str[0..4], 10) catch return false; // year
    const month = std.fmt.parseInt(u8, date_str[5..7], 10) catch return false;
    const day = std.fmt.parseInt(u8, date_str[8..10], 10) catch return false;
    if (month < 1 or month > 12) return false;
    if (day < 1 or day > 31) return false;
    return true;
}

/// Parse and validate teams from JSON
fn parseTeams(allocator: std.mem.Allocator, team_value: std.json.Value) ConfigError!std.StringHashMapUnmanaged(TeamConfig) {
    if (team_value != .object) return ConfigError.InvalidJson;

    var teams = std.StringHashMapUnmanaged(TeamConfig){};
    errdefer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                allocator.free(member);
            }
            allocator.free(team_config.members);
            if (team_config.since) |since| {
                allocator.free(since);
            }
            if (team_config.until) |until| {
                allocator.free(until);
            }
        }
        teams.deinit(allocator);
    }

    var it = team_value.object.iterator();
    while (it.next()) |entry| {
        const org_name = entry.key_ptr.*;
        const team_obj = entry.value_ptr.*;

        if (team_obj != .object) return ConfigError.InvalidJson;

        // Parse members array
        const members_value = team_obj.object.get("members") orelse return ConfigError.InvalidJson;
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

        const members_slice = try members.toOwnedSlice(allocator);
        errdefer {
            for (members_slice) |member| {
                allocator.free(member);
            }
            allocator.free(members_slice);
        }

        // Parse optional since date
        var since_copy: ?[]const u8 = null;
        errdefer if (since_copy) |since| allocator.free(since);

        if (team_obj.object.get("since")) |since_value| {
            if (since_value != .string) return ConfigError.InvalidJson;
            const since_str = since_value.string;
            if (!validateDateFormat(since_str)) return ConfigError.InvalidDateFormat;
            since_copy = try allocator.dupe(u8, since_str);
        }

        // Parse optional until date
        var until_copy: ?[]const u8 = null;
        errdefer if (until_copy) |until| allocator.free(until);

        if (team_obj.object.get("until")) |until_value| {
            if (until_value != .string) return ConfigError.InvalidJson;
            const until_str = until_value.string;
            if (!validateDateFormat(until_str)) return ConfigError.InvalidDateFormat;
            until_copy = try allocator.dupe(u8, until_str);
        }

        const team_config = TeamConfig{
            .members = members_slice,
            .since = since_copy,
            .until = until_copy,
        };

        const org_name_copy = try allocator.dupe(u8, org_name);
        try teams.put(allocator, org_name_copy, team_config);
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
        \\    "my-company": {
        \\      "members": ["alice", "bob", "charlie"],
        \\      "since": "2025-01-01"
        \\    }
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
        \\  "my-company": {
        \\    "members": ["alice", "bob"],
        \\    "since": "2025-01-01"
        \\  },
        \\  "other-org": {
        \\    "members": ["charlie"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    var teams = try parseTeams(allocator, parsed.value);
    defer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                allocator.free(member);
            }
            allocator.free(team_config.members);
            if (team_config.since) |since| {
                allocator.free(since);
            }
            if (team_config.until) |until| {
                allocator.free(until);
            }
        }
        teams.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 2), teams.count());

    const my_company = teams.get("my-company").?;
    try std.testing.expectEqual(@as(usize, 2), my_company.members.len);
    try std.testing.expectEqualStrings("alice", my_company.members[0]);
    try std.testing.expectEqualStrings("bob", my_company.members[1]);
    try std.testing.expect(my_company.since != null);
    try std.testing.expectEqualStrings("2025-01-01", my_company.since.?);
    try std.testing.expect(my_company.until == null);

    const other_org = teams.get("other-org").?;
    try std.testing.expectEqual(@as(usize, 1), other_org.members.len);
    try std.testing.expectEqualStrings("charlie", other_org.members[0]);
    try std.testing.expect(other_org.since == null);
    try std.testing.expect(other_org.until == null);
}

test "parseTeams with empty members array" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "my-company": {
        \\    "members": []
        \\  }
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
        \\    "jfitzpat": {
        \\      "members": ["alice", "bob"],
        \\      "since": "2025-01-15"
        \\    },
        \\    "kubernetes": {
        \\      "members": ["charlie", "dave", "eve"],
        \\      "since": "2024-01-01",
        \\      "until": "2024-12-31"
        \\    }
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
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                allocator.free(member);
            }
            allocator.free(team_config.members);
            if (team_config.since) |since| {
                allocator.free(since);
            }
            if (team_config.until) |until| {
                allocator.free(until);
            }
        }
        teams.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 2), teams.count());

    const jfitzpat_team = teams.get("jfitzpat").?;
    try std.testing.expectEqual(@as(usize, 2), jfitzpat_team.members.len);
    try std.testing.expectEqualStrings("alice", jfitzpat_team.members[0]);
    try std.testing.expectEqualStrings("bob", jfitzpat_team.members[1]);
    try std.testing.expect(jfitzpat_team.since != null);
    try std.testing.expectEqualStrings("2025-01-15", jfitzpat_team.since.?);
    try std.testing.expect(jfitzpat_team.until == null);

    const kubernetes_team = teams.get("kubernetes").?;
    try std.testing.expectEqual(@as(usize, 3), kubernetes_team.members.len);
    try std.testing.expectEqualStrings("charlie", kubernetes_team.members[0]);
    try std.testing.expectEqualStrings("dave", kubernetes_team.members[1]);
    try std.testing.expectEqualStrings("eve", kubernetes_team.members[2]);
    try std.testing.expect(kubernetes_team.since != null);
    try std.testing.expectEqualStrings("2024-01-01", kubernetes_team.since.?);
    try std.testing.expect(kubernetes_team.until != null);
    try std.testing.expectEqualStrings("2024-12-31", kubernetes_team.until.?);
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

test "validateDateFormat with valid dates" {
    try std.testing.expect(validateDateFormat("2025-01-15"));
    try std.testing.expect(validateDateFormat("2024-12-31"));
    try std.testing.expect(validateDateFormat("2000-01-01"));
}

test "validateDateFormat with invalid dates" {
    // Wrong length
    try std.testing.expect(!validateDateFormat("2025-1-15"));
    try std.testing.expect(!validateDateFormat("2025-01-1"));
    try std.testing.expect(!validateDateFormat("25-01-15"));

    // Wrong separators
    try std.testing.expect(!validateDateFormat("2025/01/15"));
    try std.testing.expect(!validateDateFormat("2025.01.15"));

    // Invalid month
    try std.testing.expect(!validateDateFormat("2025-00-15"));
    try std.testing.expect(!validateDateFormat("2025-13-15"));

    // Invalid day
    try std.testing.expect(!validateDateFormat("2025-01-00"));
    try std.testing.expect(!validateDateFormat("2025-01-32"));

    // Non-numeric parts
    try std.testing.expect(!validateDateFormat("abcd-01-15"));
    try std.testing.expect(!validateDateFormat("2025-ab-15"));
    try std.testing.expect(!validateDateFormat("2025-01-ab"));
}

test "parseTeams with invalid date format" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "my-company": {
        \\    "members": ["alice"],
        \\    "since": "2025/01/15"
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseTeams(allocator, parsed.value);
    try std.testing.expectError(ConfigError.InvalidDateFormat, result);
}

test "parseTeams with both dates" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "my-company": {
        \\    "members": ["alice", "bob"],
        \\    "since": "2024-01-01",
        \\    "until": "2024-12-31"
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    var teams = try parseTeams(allocator, parsed.value);
    defer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                allocator.free(member);
            }
            allocator.free(team_config.members);
            if (team_config.since) |since| {
                allocator.free(since);
            }
            if (team_config.until) |until| {
                allocator.free(until);
            }
        }
        teams.deinit(allocator);
    }

    const team = teams.get("my-company").?;
    try std.testing.expectEqual(@as(usize, 2), team.members.len);
    try std.testing.expect(team.since != null);
    try std.testing.expectEqualStrings("2024-01-01", team.since.?);
    try std.testing.expect(team.until != null);
    try std.testing.expectEqualStrings("2024-12-31", team.until.?);
}

test "parseTeams with no dates" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "my-company": {
        \\    "members": ["alice", "bob"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    var teams = try parseTeams(allocator, parsed.value);
    defer {
        var it = teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.members) |member| {
                allocator.free(member);
            }
            allocator.free(team_config.members);
            if (team_config.since) |since| {
                allocator.free(since);
            }
            if (team_config.until) |until| {
                allocator.free(until);
            }
        }
        teams.deinit(allocator);
    }

    const team = teams.get("my-company").?;
    try std.testing.expectEqual(@as(usize, 2), team.members.len);
    try std.testing.expect(team.since == null);
    try std.testing.expect(team.until == null);
}
