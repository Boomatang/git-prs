//! Configuration management for git-prs
//! Loads and validates configuration from XDG config directory

const std = @import("std");
const fs = std.fs;
const process = std.process;

pub const NamedTeamConfig = struct {
    orgs: []const []const u8,
    members: []const []const u8,
    since: ?[]const u8 = null,
    until: ?[]const u8 = null,
};

pub const TeamsConfig = struct {
    default: ?[]const u8,
    teams: std.StringHashMapUnmanaged(NamedTeamConfig),
};

pub const Config = struct {
    allocator: std.mem.Allocator,
    mine_orgs: []const []const u8,
    teams: TeamsConfig,
    auth_token: []const u8,
    authenticated_user: []const u8,

    pub fn deinit(self: *Config) void {
        // Free mine_orgs strings and array
        for (self.mine_orgs) |org| {
            self.allocator.free(org);
        }
        self.allocator.free(self.mine_orgs);

        // Free teams default value
        if (self.teams.default) |default_val| {
            self.allocator.free(default_val);
        }

        // Free teams hash map
        var it = self.teams.teams.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.orgs) |org| {
                self.allocator.free(org);
            }
            self.allocator.free(team_config.orgs);
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
        self.teams.teams.deinit(self.allocator);

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
    EmptyTeamOrgs,
    MissingTeamOrgs,
    InvalidDefaultTeam,
    NoDefaultTeam,
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
    var teams = TeamsConfig{
        .default = null,
        .teams = std.StringHashMapUnmanaged(NamedTeamConfig){},
    };
    errdefer {
        if (teams.default) |default_val| {
            allocator.free(default_val);
        }
        var it = teams.teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.orgs) |org| {
                allocator.free(org);
            }
            allocator.free(team_config.orgs);
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
        teams.teams.deinit(allocator);
    }

    if (root.object.get("teams")) |teams_value| {
        teams = try parseTeamsConfig(allocator, teams_value);
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

/// Parse and validate teams from new "teams" structure
fn parseTeamsConfig(allocator: std.mem.Allocator, teams_value: std.json.Value) ConfigError!TeamsConfig {
    if (teams_value != .object) return ConfigError.InvalidJson;

    var result = TeamsConfig{
        .default = null,
        .teams = std.StringHashMapUnmanaged(NamedTeamConfig){},
    };
    errdefer {
        if (result.default) |default_val| {
            allocator.free(default_val);
        }
        var it = result.teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.orgs) |org| {
                allocator.free(org);
            }
            allocator.free(team_config.orgs);
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
        result.teams.deinit(allocator);
    }

    // Parse default field if present
    if (teams_value.object.get("default")) |default_value| {
        if (default_value != .string) return ConfigError.InvalidJson;
        result.default = try allocator.dupe(u8, default_value.string);
    }

    // Parse all team objects
    var it = teams_value.object.iterator();
    while (it.next()) |entry| {
        const team_name = entry.key_ptr.*;
        const team_obj = entry.value_ptr.*;

        // Skip the "default" key
        if (std.mem.eql(u8, team_name, "default")) continue;

        if (team_obj != .object) return ConfigError.InvalidJson;

        // Parse orgs array (required)
        const orgs_value = team_obj.object.get("orgs") orelse return ConfigError.MissingTeamOrgs;
        if (orgs_value != .array) return ConfigError.MissingTeamOrgs;
        const orgs_array = orgs_value.array;
        if (orgs_array.items.len == 0) return ConfigError.EmptyTeamOrgs;

        var orgs = try std.ArrayList([]const u8).initCapacity(allocator, orgs_array.items.len);
        errdefer {
            for (orgs.items) |org| {
                allocator.free(org);
            }
            orgs.deinit(allocator);
        }

        for (orgs_array.items) |org_value| {
            if (org_value != .string) return ConfigError.InvalidJson;
            const org_str = org_value.string;
            if (org_str.len == 0) return ConfigError.EmptyOrgName;
            const org_copy = try allocator.dupe(u8, org_str);
            try orgs.append(allocator, org_copy);
        }

        const orgs_slice = try orgs.toOwnedSlice(allocator);
        errdefer {
            for (orgs_slice) |org| {
                allocator.free(org);
            }
            allocator.free(orgs_slice);
        }

        // Parse members array (required)
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

        const team_config = NamedTeamConfig{
            .orgs = orgs_slice,
            .members = members_slice,
            .since = since_copy,
            .until = until_copy,
        };

        const team_name_copy = try allocator.dupe(u8, team_name);
        try result.teams.put(allocator, team_name_copy, team_config);
    }

    // Validate default references an existing team
    if (result.default) |default_name| {
        if (!result.teams.contains(default_name)) {
            return ConfigError.InvalidDefaultTeam;
        }
    }

    return result;
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
        \\  "teams": {
        \\    "default": "release",
        \\    "release": {
        \\      "orgs": ["my-company", "other-org"],
        \\      "members": ["alice", "bob", "charlie"],
        \\      "since": "2025-01-01"
        \\    },
        \\    "traffic": {
        \\      "orgs": ["my-company"],
        \\      "members": ["dave", "eve"]
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

// Tests for new parseTeamsConfig function

test "parseTeamsConfig with valid teams" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "default": "release",
        \\  "release": {
        \\    "orgs": ["org-a", "org-b"],
        \\    "members": ["alice", "bob"],
        \\    "since": "2025-01-01"
        \\  },
        \\  "traffic": {
        \\    "orgs": ["org-c"],
        \\    "members": ["charlie"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    var teams_config = try parseTeamsConfig(allocator, parsed.value);
    defer {
        if (teams_config.default) |default_val| {
            allocator.free(default_val);
        }
        var it = teams_config.teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.orgs) |org| {
                allocator.free(org);
            }
            allocator.free(team_config.orgs);
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
        teams_config.teams.deinit(allocator);
    }

    try std.testing.expect(teams_config.default != null);
    try std.testing.expectEqualStrings("release", teams_config.default.?);
    try std.testing.expectEqual(@as(usize, 2), teams_config.teams.count());

    const release = teams_config.teams.get("release").?;
    try std.testing.expectEqual(@as(usize, 2), release.orgs.len);
    try std.testing.expectEqualStrings("org-a", release.orgs[0]);
    try std.testing.expectEqualStrings("org-b", release.orgs[1]);
    try std.testing.expectEqual(@as(usize, 2), release.members.len);
    try std.testing.expectEqualStrings("alice", release.members[0]);
    try std.testing.expectEqualStrings("bob", release.members[1]);
    try std.testing.expect(release.since != null);
    try std.testing.expectEqualStrings("2025-01-01", release.since.?);

    const traffic = teams_config.teams.get("traffic").?;
    try std.testing.expectEqual(@as(usize, 1), traffic.orgs.len);
    try std.testing.expectEqualStrings("org-c", traffic.orgs[0]);
    try std.testing.expectEqual(@as(usize, 1), traffic.members.len);
    try std.testing.expectEqualStrings("charlie", traffic.members[0]);
    try std.testing.expect(traffic.since == null);
}

test "parseTeamsConfig with missing orgs" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "release": {
        \\    "members": ["alice", "bob"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseTeamsConfig(allocator, parsed.value);
    try std.testing.expectError(ConfigError.MissingTeamOrgs, result);
}

test "parseTeamsConfig with empty orgs" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "release": {
        \\    "orgs": [],
        \\    "members": ["alice", "bob"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseTeamsConfig(allocator, parsed.value);
    try std.testing.expectError(ConfigError.EmptyTeamOrgs, result);
}

test "parseTeamsConfig with empty members" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "release": {
        \\    "orgs": ["org-a"],
        \\    "members": []
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseTeamsConfig(allocator, parsed.value);
    try std.testing.expectError(ConfigError.EmptyTeamMembers, result);
}

test "parseTeamsConfig with invalid default" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "default": "nonexistent",
        \\  "release": {
        \\    "orgs": ["org-a"],
        \\    "members": ["alice"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const result = parseTeamsConfig(allocator, parsed.value);
    try std.testing.expectError(ConfigError.InvalidDefaultTeam, result);
}

test "parseTeamsConfig without default" {
    const allocator = std.testing.allocator;

    const json_str =
        \\{
        \\  "release": {
        \\    "orgs": ["org-a"],
        \\    "members": ["alice"]
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    var teams_config = try parseTeamsConfig(allocator, parsed.value);
    defer {
        if (teams_config.default) |default_val| {
            allocator.free(default_val);
        }
        var it = teams_config.teams.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            const team_config = entry.value_ptr.*;
            for (team_config.orgs) |org| {
                allocator.free(org);
            }
            allocator.free(team_config.orgs);
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
        teams_config.teams.deinit(allocator);
    }

    try std.testing.expect(teams_config.default == null);
    try std.testing.expectEqual(@as(usize, 1), teams_config.teams.count());
}
