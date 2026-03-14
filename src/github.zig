const std = @import("std");

// ============================================================================
// Public Data Structures
// ============================================================================

pub const PullRequest = struct {
    org: []const u8,
    repo: []const u8,
    number: u32,
    title: []const u8,
    url: []const u8,
    author: []const u8,
    created_at: i64, // unix timestamp
    last_comment_at: ?i64, // null if no comments
    unique_commenters: u32, // count excluding PR author
    is_draft: bool,

    pub fn deinit(self: *const PullRequest, allocator: std.mem.Allocator) void {
        allocator.free(self.org);
        allocator.free(self.repo);
        allocator.free(self.title);
        allocator.free(self.url);
        allocator.free(self.author);
    }
};

pub const GitHubError = error{
    NetworkError,
    AuthError,
    RateLimitExceeded,
    ParseError,
    GhCommandFailed,
} || std.mem.Allocator.Error || std.process.Child.SpawnError;

pub const Client = struct {
    allocator: std.mem.Allocator,
    auth_token: []const u8,

    pub fn init(allocator: std.mem.Allocator, auth_token: []const u8) Client {
        return .{
            .allocator = allocator,
            .auth_token = auth_token,
        };
    }

    pub fn deinit(self: *Client) void {
        _ = self;
        // Nothing to clean up since we use subprocess calls
    }
};

// ============================================================================
// Public API Functions
// ============================================================================

/// Get the authenticated user's login name using `gh api`
pub fn getAuthenticatedUser(client: *Client) GitHubError![]const u8 {
    const result = std.process.Child.run(.{
        .allocator = client.allocator,
        .argv = &.{ "gh", "api", "/user", "--jq", ".login" },
    }) catch return error.GhCommandFailed;
    defer client.allocator.free(result.stdout);
    defer client.allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return error.AuthError;
    }

    const login = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);
    return try client.allocator.dupe(u8, login);
}

/// Fetch PRs authored by authenticated user in specified orgs
pub fn fetchUserPRs(
    client: *Client,
    orgs: []const []const u8,
    org_filter: ?[]const u8,
    limit: u32,
    since: ?[]const u8,
    until: ?[]const u8,
) GitHubError![]PullRequest {
    var all_prs: std.ArrayListUnmanaged(PullRequest) = .empty;
    errdefer {
        for (all_prs.items) |*pr| {
            pr.deinit(client.allocator);
        }
        all_prs.deinit(client.allocator);
    }

    for (orgs) |org| {
        // Apply org filter if specified (case-insensitive)
        if (org_filter) |filter| {
            if (!std.ascii.eqlIgnoreCase(org, filter)) {
                continue;
            }
        }

        const remaining = limit - @as(u32, @intCast(all_prs.items.len));
        const prs = try fetchPRsWithGh(client, org, null, remaining, since, until);
        defer client.allocator.free(prs);

        for (prs) |pr| {
            try all_prs.append(client.allocator, pr);
            if (all_prs.items.len >= limit) break;
        }

        if (all_prs.items.len >= limit) break;
    }

    return all_prs.toOwnedSlice(client.allocator);
}

/// Fetch PRs authored by team members in specified org
pub fn fetchTeamPRs(
    client: *Client,
    org: []const u8,
    members: []const []const u8,
    member_filter: ?[]const u8,
    since: ?[]const u8,
    until: ?[]const u8,
) GitHubError![]PullRequest {
    var all_prs: std.ArrayListUnmanaged(PullRequest) = .empty;
    errdefer {
        for (all_prs.items) |*pr| {
            pr.deinit(client.allocator);
        }
        all_prs.deinit(client.allocator);
    }

    for (members) |member| {
        // Apply member filter if specified
        if (member_filter) |filter| {
            if (!std.mem.eql(u8, member, filter)) {
                continue;
            }
        }

        const prs = try fetchPRsForAuthor(client, org, member, since, until);
        defer client.allocator.free(prs);

        for (prs) |pr| {
            try all_prs.append(client.allocator, pr);
        }
    }

    return all_prs.toOwnedSlice(client.allocator);
}

/// Fetch merged PRs authored by authenticated user in specified orgs
pub fn fetchMergedPRs(
    client: *Client,
    orgs: []const []const u8,
    org_filter: ?[]const u8,
    since: []const u8,
    until: ?[]const u8,
) GitHubError![]PullRequest {
    var all_prs: std.ArrayListUnmanaged(PullRequest) = .empty;
    errdefer {
        for (all_prs.items) |*pr| {
            pr.deinit(client.allocator);
        }
        all_prs.deinit(client.allocator);
    }

    for (orgs) |org| {
        // Apply org filter if specified (case-insensitive)
        if (org_filter) |filter| {
            if (!std.ascii.eqlIgnoreCase(org, filter)) {
                continue;
            }
        }

        const prs = try fetchMergedPRsWithGh(client, org, since, until);
        defer client.allocator.free(prs);

        for (prs) |pr| {
            try all_prs.append(client.allocator, pr);
        }
    }

    return all_prs.toOwnedSlice(client.allocator);
}

// ============================================================================
// Internal Helper Functions
// ============================================================================

fn fetchPRsWithGh(
    client: *Client,
    org: []const u8,
    author: ?[]const u8,
    limit: u32,
    since: ?[]const u8,
    until: ?[]const u8,
) GitHubError![]PullRequest {
    // Build search query for GraphQL
    const base_query = if (author) |a|
        try std.fmt.allocPrint(client.allocator, "is:pr is:open author:{s} org:{s}", .{ a, org })
    else
        try std.fmt.allocPrint(client.allocator, "is:pr is:open author:@me org:{s}", .{org});
    defer client.allocator.free(base_query);

    // Append date filters if provided
    const search_query = if (since != null or until != null) blk: {
        const since_filter = if (since) |s|
            try std.fmt.allocPrint(client.allocator, " created:>={s}", .{s})
        else
            try std.fmt.allocPrint(client.allocator, "", .{});
        defer client.allocator.free(since_filter);

        const until_filter = if (until) |u|
            try std.fmt.allocPrint(client.allocator, " created:<={s}", .{u})
        else
            try std.fmt.allocPrint(client.allocator, "", .{});
        defer client.allocator.free(until_filter);

        break :blk try std.fmt.allocPrint(client.allocator, "{s}{s}{s}", .{ base_query, since_filter, until_filter });
    } else base_query: {
        break :base_query try client.allocator.dupe(u8, base_query);
    };
    defer client.allocator.free(search_query);

    // Build GraphQL query
    const graphql_query = try std.fmt.allocPrint(client.allocator,
        \\query {{
        \\  search(query: "{s}", type: ISSUE, first: {d}) {{
        \\    nodes {{
        \\      ... on PullRequest {{
        \\        number
        \\        title
        \\        url
        \\        createdAt
        \\        isDraft
        \\        author {{ login }}
        \\        repository {{
        \\          name
        \\          owner {{ login }}
        \\        }}
        \\        comments(last: 100) {{
        \\          nodes {{
        \\            author {{ login }}
        \\            createdAt
        \\          }}
        \\        }}
        \\      }}
        \\    }}
        \\  }}
        \\}}
    , .{ search_query, limit });
    defer client.allocator.free(graphql_query);

    // Build the query parameter
    const query_param = try std.fmt.allocPrint(client.allocator, "query={s}", .{graphql_query});
    defer client.allocator.free(query_param);

    // Use gh api graphql to fetch PRs
    const result = std.process.Child.run(.{
        .allocator = client.allocator,
        .argv = &.{
            "gh", "api", "graphql",
            "-f", query_param,
        },
    }) catch return error.GhCommandFailed;
    defer client.allocator.free(result.stdout);
    defer client.allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return error.GhCommandFailed;
    }

    return try parseGraphQLResponse(client.allocator, result.stdout);
}

fn fetchPRsForAuthor(
    client: *Client,
    org: []const u8,
    author: []const u8,
    since: ?[]const u8,
    until: ?[]const u8,
) GitHubError![]PullRequest {
    return fetchPRsWithGh(client, org, author, 100, since, until);
}

fn fetchMergedPRsWithGh(
    client: *Client,
    org: []const u8,
    since: []const u8,
    until: ?[]const u8,
) GitHubError![]PullRequest {
    // Build search query for merged PRs
    const base_query = try std.fmt.allocPrint(client.allocator, "is:pr is:merged author:@me org:{s}", .{org});
    defer client.allocator.free(base_query);

    // Add merged date filters
    const since_filter = try std.fmt.allocPrint(client.allocator, " merged:>={s}", .{since});
    defer client.allocator.free(since_filter);

    const until_filter = if (until) |u|
        try std.fmt.allocPrint(client.allocator, " merged:<={s}", .{u})
    else
        try std.fmt.allocPrint(client.allocator, "", .{});
    defer client.allocator.free(until_filter);

    const search_query = try std.fmt.allocPrint(client.allocator, "{s}{s}{s}", .{ base_query, since_filter, until_filter });
    defer client.allocator.free(search_query);

    // Build GraphQL query
    const graphql_query = try std.fmt.allocPrint(client.allocator,
        \\query {{
        \\  search(query: "{s}", type: ISSUE, first: 100) {{
        \\    nodes {{
        \\      ... on PullRequest {{
        \\        number
        \\        title
        \\        url
        \\        createdAt
        \\        isDraft
        \\        author {{ login }}
        \\        repository {{
        \\          name
        \\          owner {{ login }}
        \\        }}
        \\        comments(last: 100) {{
        \\          nodes {{
        \\            author {{ login }}
        \\            createdAt
        \\          }}
        \\        }}
        \\      }}
        \\    }}
        \\  }}
        \\}}
    , .{search_query});
    defer client.allocator.free(graphql_query);

    // Build the query parameter
    const query_param = try std.fmt.allocPrint(client.allocator, "query={s}", .{graphql_query});
    defer client.allocator.free(query_param);

    // Use gh api graphql to fetch PRs
    const result = std.process.Child.run(.{
        .allocator = client.allocator,
        .argv = &.{
            "gh", "api", "graphql",
            "-f", query_param,
        },
    }) catch return error.GhCommandFailed;
    defer client.allocator.free(result.stdout);
    defer client.allocator.free(result.stderr);

    if (result.term.Exited != 0) {
        return error.GhCommandFailed;
    }

    return try parseGraphQLResponse(client.allocator, result.stdout);
}

fn parseGraphQLResponse(allocator: std.mem.Allocator, json_data: []const u8) GitHubError![]PullRequest {
    const parsed = std.json.parseFromSlice(
        std.json.Value,
        allocator,
        json_data,
        .{},
    ) catch return error.ParseError;
    defer parsed.deinit();

    // Navigate: data.search.nodes
    if (parsed.value != .object) return error.ParseError;
    const data = parsed.value.object.get("data") orelse return error.ParseError;
    if (data != .object) return error.ParseError;
    const search = data.object.get("search") orelse return error.ParseError;
    if (search != .object) return error.ParseError;
    const nodes = search.object.get("nodes") orelse return error.ParseError;
    if (nodes != .array) return error.ParseError;

    var prs: std.ArrayListUnmanaged(PullRequest) = .empty;
    errdefer {
        for (prs.items) |*pr| {
            pr.deinit(allocator);
        }
        prs.deinit(allocator);
    }

    for (nodes.array.items) |item| {
        if (item != .object) continue;

        const pr = try parsePullRequestFromGraphQL(allocator, item.object);
        try prs.append(allocator, pr);
    }

    return prs.toOwnedSlice(allocator);
}

fn parsePullRequestFromGraphQL(allocator: std.mem.Allocator, obj: std.json.ObjectMap) GitHubError!PullRequest {
    const number = obj.get("number") orelse return error.ParseError;
    const title = obj.get("title") orelse return error.ParseError;
    const url = obj.get("url") orelse return error.ParseError;
    const created_at_str = obj.get("createdAt") orelse return error.ParseError;
    const is_draft_value = obj.get("isDraft") orelse return error.ParseError;
    const author_obj = obj.get("author") orelse return error.ParseError;
    const repository = obj.get("repository") orelse return error.ParseError;

    // Parse author
    const author_str = if (author_obj == .null)
        "ghost"
    else if (author_obj == .object) blk: {
        const login = author_obj.object.get("login") orelse return error.ParseError;
        break :blk login.string;
    } else
        return error.ParseError;

    // Parse repository
    if (repository != .object) return error.ParseError;
    const repo_obj = repository.object;
    const owner = repo_obj.get("owner") orelse return error.ParseError;
    const repo_name = repo_obj.get("name") orelse return error.ParseError;

    if (owner != .object) return error.ParseError;
    const owner_login = owner.object.get("login") orelse return error.ParseError;

    // Parse timestamps
    const created_at = try parseIso8601Timestamp(created_at_str.string);

    // Parse is_draft boolean
    const is_draft = if (is_draft_value == .bool) is_draft_value.bool else false;

    // Analyze comments from GraphQL response
    var last_comment_at: ?i64 = null;
    var unique_commenters: u32 = 0;

    if (obj.get("comments")) |comments_obj| {
        if (comments_obj == .object) {
            if (comments_obj.object.get("nodes")) |comment_nodes| {
                if (comment_nodes == .array) {
                    const analysis = analyzeComments(allocator, comment_nodes.array, author_str);
                    last_comment_at = analysis.last_comment_at;
                    unique_commenters = analysis.unique_commenters;
                }
            }
        }
    }

    return .{
        .org = try allocator.dupe(u8, owner_login.string),
        .repo = try allocator.dupe(u8, repo_name.string),
        .number = @intCast(number.integer),
        .title = try allocator.dupe(u8, title.string),
        .url = try allocator.dupe(u8, url.string),
        .author = try allocator.dupe(u8, author_str),
        .created_at = created_at,
        .last_comment_at = last_comment_at,
        .unique_commenters = unique_commenters,
        .is_draft = is_draft,
    };
}

const CommentAnalysis = struct {
    last_comment_at: ?i64,
    unique_commenters: u32,
};

fn analyzeComments(
    allocator: std.mem.Allocator,
    comments: std.json.Array,
    pr_author: []const u8,
) CommentAnalysis {
    var last_timestamp: ?i64 = null;
    var commenter_set = std.StringHashMap(void).init(allocator);
    defer commenter_set.deinit();

    for (comments.items) |comment_node| {
        if (comment_node != .object) continue;

        const comment = comment_node.object;
        const author_obj = comment.get("author") orelse continue;
        const created_at_str = comment.get("createdAt") orelse continue;

        const comment_author = if (author_obj == .null)
            "ghost"
        else if (author_obj == .object) blk: {
            const login = author_obj.object.get("login") orelse continue;
            break :blk login.string;
        } else
            continue;

        const timestamp = parseIso8601Timestamp(created_at_str.string) catch continue;

        // Update last_timestamp if this is newer
        if (last_timestamp == null or timestamp > last_timestamp.?) {
            last_timestamp = timestamp;
        }

        // Add to unique commenters set (excluding PR author)
        if (!std.mem.eql(u8, comment_author, pr_author)) {
            commenter_set.put(comment_author, {}) catch {};
        }
    }

    return .{
        .last_comment_at = last_timestamp,
        .unique_commenters = @intCast(commenter_set.count()),
    };
}

fn parseIso8601Timestamp(iso_string: []const u8) GitHubError!i64 {
    // Parse ISO 8601 timestamp to Unix timestamp
    // Example format: "2024-01-15T12:34:56Z"

    // Simple parser for GitHub's ISO 8601 format
    if (iso_string.len < 19) return error.ParseError;

    const year = std.fmt.parseInt(i32, iso_string[0..4], 10) catch return error.ParseError;
    const month = std.fmt.parseInt(u8, iso_string[5..7], 10) catch return error.ParseError;
    const day = std.fmt.parseInt(u8, iso_string[8..10], 10) catch return error.ParseError;
    const hour = std.fmt.parseInt(u8, iso_string[11..13], 10) catch return error.ParseError;
    const minute = std.fmt.parseInt(u8, iso_string[14..16], 10) catch return error.ParseError;
    const second = std.fmt.parseInt(u8, iso_string[17..19], 10) catch return error.ParseError;

    // Calculate Unix timestamp (days since epoch * seconds per day + time of day)
    const days_since_epoch = daysSinceEpoch(year, month, day);
    const seconds_in_day = @as(i64, hour) * 3600 + @as(i64, minute) * 60 + @as(i64, second);

    return days_since_epoch * 86400 + seconds_in_day;
}

fn daysSinceEpoch(year: i32, month: u8, day: u8) i64 {
    // Unix epoch: January 1, 1970
    var y = year;
    var m = month;

    // Adjust for months (Mar=1..Dec=10, Jan=11, Feb=12)
    if (m <= 2) {
        y -= 1;
        m += 12;
    }

    const days_in_year = 365 * y;
    const leap_days = @divFloor(y, 4) - @divFloor(y, 100) + @divFloor(y, 400);
    const days_in_months = @divFloor(153 * @as(i64, m - 3) + 2, 5);
    const total_days = @as(i64, days_in_year) + leap_days + days_in_months + @as(i64, day) - 719469;

    return total_days;
}

// ============================================================================
// Tests
// ============================================================================

test "parseIso8601Timestamp" {
    // Test known timestamp: 2024-01-15T12:34:56Z
    const timestamp = try parseIso8601Timestamp("2024-01-15T12:34:56Z");

    // Expected: January 15, 2024, 12:34:56 UTC
    // This is approximately 1705322096 (verified with external tools)
    try std.testing.expect(timestamp > 1705322000);
    try std.testing.expect(timestamp < 1705323000);
}

test "parseIso8601Timestamp epoch" {
    // Test Unix epoch: 1970-01-01T00:00:00Z
    const timestamp = try parseIso8601Timestamp("1970-01-01T00:00:00Z");
    try std.testing.expectEqual(@as(i64, 0), timestamp);
}

test "Client init and deinit" {
    const allocator = std.testing.allocator;
    const token = "test-token";

    var client = Client.init(allocator, token);
    defer client.deinit();

    try std.testing.expectEqual(allocator, client.allocator);
    try std.testing.expectEqualStrings(token, client.auth_token);
}

test "org filter comparison is case-insensitive" {
    // Verify that std.ascii.eqlIgnoreCase works as expected for org matching
    // This mirrors the logic used in fetchUserPRs
    const org = "Kubernetes";
    const filter_lower = "kubernetes";
    const filter_upper = "KUBERNETES";
    const filter_mixed = "KuBeRnEtEs";
    const filter_exact = "Kubernetes";
    const filter_wrong = "kubernetess";

    // Case-insensitive matches should succeed
    try std.testing.expect(std.ascii.eqlIgnoreCase(org, filter_lower));
    try std.testing.expect(std.ascii.eqlIgnoreCase(org, filter_upper));
    try std.testing.expect(std.ascii.eqlIgnoreCase(org, filter_mixed));
    try std.testing.expect(std.ascii.eqlIgnoreCase(org, filter_exact));

    // Different string should not match
    try std.testing.expect(!std.ascii.eqlIgnoreCase(org, filter_wrong));
}
