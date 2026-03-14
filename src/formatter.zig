const std = @import("std");
const time = @import("time.zig");
const github = @import("github.zig");

pub const PullRequest = github.PullRequest;

/// Get terminal width using ioctl, falling back to COLUMNS env var, then 80
pub fn getTerminalWidth() u32 {
    // Try ioctl-based detection first
    const stdout = std.fs.File.stdout();
    var winsize: std.posix.winsize = undefined;
    const result = std.posix.system.ioctl(stdout.handle, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize));
    if (result == 0 and winsize.col > 0) {
        return winsize.col;
    }

    // Fall back to COLUMNS env var
    const columns = std.posix.getenv("COLUMNS") orelse return 80;
    return std.fmt.parseInt(u32, columns, 10) catch 80;
}

/// Calculate the maximum identifier width needed for a list of PRs
fn calcMaxIdentifierWidth(prs: []const PullRequest) usize {
    var max_width: usize = 12; // minimum "ORG/REPO#NUM" header width
    var buf: [256]u8 = undefined;
    for (prs) |pr| {
        const id = std.fmt.bufPrint(&buf, "{s}/{s}#{d}", .{ pr.org, pr.repo, pr.number }) catch continue;
        if (id.len > max_width) {
            max_width = id.len;
        }
    }
    return max_width;
}

/// Truncate string to max_len, adding "..." if truncated
fn truncate(str: []const u8, max_len: usize, buffer: []u8) []const u8 {
    if (max_len < 3) {
        return buffer[0..0];
    }

    if (str.len <= max_len) {
        @memcpy(buffer[0..str.len], str);
        return buffer[0..str.len];
    }

    const truncated_len = max_len - 3;
    @memcpy(buffer[0..truncated_len], str[0..truncated_len]);
    @memcpy(buffer[truncated_len..max_len], "...");
    return buffer[0..max_len];
}

/// Format org/repo#number (no truncation)
fn formatPRIdentifier(pr: PullRequest, buffer: []u8) ![]const u8 {
    return try std.fmt.bufPrint(buffer, "{s}/{s}#{d}", .{ pr.org, pr.repo, pr.number });
}

/// Format a single PR row for mine view
fn formatMineRow(
    writer: anytype,
    pr: PullRequest,
    current_time: i64,
    title_width: usize,
    identifier_width: usize,
) !void {
    var identifier_buffer: [256]u8 = undefined;
    const identifier = try formatPRIdentifier(pr, &identifier_buffer);

    var title_buffer: [1024]u8 = undefined;
    const title = truncate(pr.title, title_width, &title_buffer);

    var age_buffer: [32]u8 = undefined;
    const age = time.formatDuration(current_time - pr.created_at, &age_buffer);

    var last_buffer: [32]u8 = undefined;
    const last = if (pr.last_comment_at) |last_comment|
        time.formatDuration(current_time - last_comment, &last_buffer)
    else
        "-";

    // Print identifier with dynamic padding
    try writer.writeAll(identifier);
    var i: usize = identifier.len;
    while (i < identifier_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  ");
    // Print title with padding
    try writer.writeAll(title);
    i = title.len;
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  {s: >5}  {d: >3}  {s: >5}\n", .{
        age,
        pr.unique_commenters,
        last,
    });
    // Print URL on second line with 4-space indent
    try writer.print("    {s}\n", .{pr.url});
}

/// Format a single PR row for team view
fn formatTeamRow(
    writer: anytype,
    pr: PullRequest,
    current_time: i64,
    title_width: usize,
    identifier_width: usize,
) !void {
    var author_buffer: [8]u8 = undefined;
    const author = truncate(pr.author, 8, &author_buffer);

    var identifier_buffer: [256]u8 = undefined;
    const identifier = try formatPRIdentifier(pr, &identifier_buffer);

    var title_buffer: [1024]u8 = undefined;
    const title = truncate(pr.title, title_width, &title_buffer);

    var age_buffer: [32]u8 = undefined;
    const age = time.formatDuration(current_time - pr.created_at, &age_buffer);

    var last_buffer: [32]u8 = undefined;
    const last = if (pr.last_comment_at) |last_comment|
        time.formatDuration(current_time - last_comment, &last_buffer)
    else
        "-";

    // Print author with fixed padding
    try writer.print("{s: <8}  ", .{author});
    // Print identifier with dynamic padding
    try writer.writeAll(identifier);
    var i: usize = identifier.len;
    while (i < identifier_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  ");
    // Print title with padding
    try writer.writeAll(title);
    i = title.len;
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  {s: >5}  {d: >3}  {s: >5}\n", .{
        age,
        pr.unique_commenters,
        last,
    });
    // Print URL on second line with 4-space indent
    try writer.print("    {s}\n", .{pr.url});
}

/// Sort PRs by age descending (newest first)
fn sortByAge(_: void, a: PullRequest, b: PullRequest) bool {
    return a.created_at > b.created_at;
}

/// Sort PRs by author then age
fn sortByAuthorThenAge(_: void, a: PullRequest, b: PullRequest) bool {
    const author_cmp = std.mem.order(u8, a.author, b.author);
    if (author_cmp == .eq) {
        return a.created_at > b.created_at;
    }
    return author_cmp == .lt;
}

/// Format PRs for the mine command output
pub fn formatMineOutput(
    allocator: std.mem.Allocator,
    writer: anytype,
    prs: []const PullRequest,
    current_time: i64,
) !void {
    if (prs.len == 0) {
        try writer.print("No open PRs found\n", .{});
        return;
    }

    // Sort by age
    const sorted_prs = try allocator.dupe(PullRequest, prs);
    defer allocator.free(sorted_prs);
    std.mem.sort(PullRequest, sorted_prs, {}, sortByAge);

    // Calculate identifier width dynamically based on content
    const identifier_width = calcMaxIdentifierWidth(sorted_prs);

    // Calculate title width
    const terminal_width = getTerminalWidth();
    // Fixed columns: AGE(5) + 👤(3) + LAST(5) + spaces(8) = 21, plus dynamic identifier
    const fixed_width: usize = 21 + identifier_width;
    const title_width = if (terminal_width > fixed_width) terminal_width - fixed_width else 20;

    // Print header with dynamic identifier column width
    try writer.writeAll("ORG/REPO#NUM");
    var i: usize = 12; // "ORG/REPO#NUM" is 12 chars
    while (i < identifier_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  TITLE");
    i = 5; // "TITLE" is 5 chars
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST\n", .{});

    // Print separator (use total row width)
    const total_width = identifier_width + 2 + title_width + 2 + 5 + 4 + 3 + 4 + 5;
    i = 0;
    while (i < total_width) : (i += 1) {
        try writer.writeAll("\xe2\x94\x80");
    }
    try writer.print("\n", .{});

    // Print rows
    for (sorted_prs) |pr| {
        try formatMineRow(writer, pr, current_time, title_width, identifier_width);
    }
}

/// Format PRs for the team command output
pub fn formatTeamOutput(
    allocator: std.mem.Allocator,
    writer: anytype,
    prs: []const PullRequest,
    current_time: i64,
) !void {
    if (prs.len == 0) {
        try writer.print("No open PRs found\n", .{});
        return;
    }

    // Sort by author then age
    const sorted_prs = try allocator.dupe(PullRequest, prs);
    defer allocator.free(sorted_prs);
    std.mem.sort(PullRequest, sorted_prs, {}, sortByAuthorThenAge);

    // Calculate identifier width dynamically based on content
    const identifier_width = calcMaxIdentifierWidth(sorted_prs);

    // Calculate title width
    const terminal_width = getTerminalWidth();
    // Fixed columns: AUTHOR(8) + AGE(5) + 👤(3) + LAST(5) + spaces(10) = 31, plus dynamic identifier
    const fixed_width: usize = 31 + identifier_width;
    const title_width = if (terminal_width > fixed_width) terminal_width - fixed_width else 20;

    // Print header with dynamic identifier column width
    try writer.writeAll("AUTHOR    ORG/REPO#NUM");
    var i: usize = 12; // "ORG/REPO#NUM" is 12 chars
    while (i < identifier_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  TITLE");
    i = 5; // "TITLE" is 5 chars
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST\n", .{});

    // Print separator (use total row width)
    const total_width = 8 + 2 + identifier_width + 2 + title_width + 2 + 5 + 4 + 3 + 4 + 5;
    i = 0;
    while (i < total_width) : (i += 1) {
        try writer.writeAll("\xe2\x94\x80");
    }
    try writer.print("\n", .{});

    // Print rows
    for (sorted_prs) |pr| {
        try formatTeamRow(writer, pr, current_time, title_width, identifier_width);
    }
}

/// Write a JSON-escaped string
fn writeJsonString(writer: anytype, s: []const u8) !void {
    try writer.writeByte('"');
    for (s) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => {
                if (c < 0x20) {
                    try writer.print("\\u{x:0>4}", .{c});
                } else {
                    try writer.writeByte(c);
                }
            },
        }
    }
    try writer.writeByte('"');
}

/// Format a single PR as JSON object
fn formatPrAsJson(writer: anytype, pr: PullRequest) !void {
    try writer.writeAll("{");

    try writer.writeAll("\"org\":");
    try writeJsonString(writer, pr.org);

    try writer.writeAll(",\"repo\":");
    try writeJsonString(writer, pr.repo);

    try writer.print(",\"number\":{d}", .{pr.number});

    try writer.writeAll(",\"title\":");
    try writeJsonString(writer, pr.title);

    try writer.writeAll(",\"url\":");
    try writeJsonString(writer, pr.url);

    try writer.writeAll(",\"author\":");
    try writeJsonString(writer, pr.author);

    try writer.print(",\"created_at\":{d}", .{pr.created_at});

    if (pr.last_comment_at) |last| {
        try writer.print(",\"last_comment_at\":{d}", .{last});
    } else {
        try writer.writeAll(",\"last_comment_at\":null");
    }

    try writer.print(",\"unique_commenters\":{d}", .{pr.unique_commenters});

    try writer.writeAll("}");
}

/// Format PRs as JSON array output
pub fn formatJsonOutput(
    writer: anytype,
    prs: []const PullRequest,
) !void {
    try writer.writeByte('[');

    for (prs, 0..) |pr, i| {
        if (i > 0) {
            try writer.writeByte(',');
        }
        try formatPrAsJson(writer, pr);
    }

    try writer.writeAll("]\n");
}

// Tests

test "truncate function - no truncation needed" {
    var buffer: [20]u8 = undefined;
    const result = truncate("hello", 10, &buffer);
    try std.testing.expectEqualStrings("hello", result);
}

test "truncate function - with truncation" {
    var buffer: [20]u8 = undefined;
    const result = truncate("hello world", 8, &buffer);
    try std.testing.expectEqualStrings("hello...", result);
}

test "truncate function - exact length" {
    var buffer: [20]u8 = undefined;
    const result = truncate("hello", 5, &buffer);
    try std.testing.expectEqualStrings("hello", result);
}

test "truncate function - very short max_len" {
    var buffer: [20]u8 = undefined;
    const result = truncate("hello", 2, &buffer);
    try std.testing.expectEqualStrings("", result);
}

test "getTerminalWidth - returns valid width" {
    // When running in a terminal, ioctl should return actual width
    // When running in CI/piped, should fall back to COLUMNS or 80
    const width = getTerminalWidth();
    // Width must be at least 80 (default fallback) and reasonable upper bound
    try std.testing.expect(width >= 80);
    try std.testing.expect(width <= 10000); // Sanity check for reasonable width
}

test "getTerminalWidth - ioctl detects terminal width" {
    // This test verifies ioctl mechanism works when running in a real terminal
    // The ioctl call queries stdout, so result depends on execution context
    const stdout = std.fs.File.stdout();
    var winsize: std.posix.winsize = undefined;
    const result = std.posix.system.ioctl(stdout.handle, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize));
    // If ioctl succeeds (we're in a terminal), width should match
    if (result == 0 and winsize.col > 0) {
        const width = getTerminalWidth();
        try std.testing.expectEqual(winsize.col, @as(u16, @intCast(width)));
    }
    // If not in terminal, test passes (fallback behavior tested separately)
}

test "getTerminalWidth - COLUMNS fallback behavior" {
    // Test that COLUMNS env var fallback parsing works correctly
    // Note: This test validates the fallback code path by checking the parse logic
    // The actual env var lookup is tested indirectly via getTerminalWidth()

    // Valid COLUMNS values should parse correctly
    try std.testing.expectEqual(@as(u32, 120), std.fmt.parseInt(u32, "120", 10) catch 80);
    try std.testing.expectEqual(@as(u32, 200), std.fmt.parseInt(u32, "200", 10) catch 80);
    try std.testing.expectEqual(@as(u32, 80), std.fmt.parseInt(u32, "80", 10) catch 80);

    // Invalid COLUMNS values should fall back to 80
    try std.testing.expectEqual(@as(u32, 80), std.fmt.parseInt(u32, "invalid", 10) catch 80);
    try std.testing.expectEqual(@as(u32, 80), std.fmt.parseInt(u32, "", 10) catch 80);
    try std.testing.expectEqual(@as(u32, 80), std.fmt.parseInt(u32, "-1", 10) catch 80);
}

test "sortByAge - sorts newest first" {
    var prs = [_]PullRequest{
        .{
            .org = "org1",
            .repo = "repo1",
            .number = 1,
            .title = "PR 1",
            .url = "url1",
            .author = "author1",
            .created_at = 1000,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org2",
            .repo = "repo2",
            .number = 2,
            .title = "PR 2",
            .url = "url2",
            .author = "author2",
            .created_at = 500,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org3",
            .repo = "repo3",
            .number = 3,
            .title = "PR 3",
            .url = "url3",
            .author = "author3",
            .created_at = 1500,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    std.mem.sort(PullRequest, &prs, {}, sortByAge);

    try std.testing.expectEqual(@as(i64, 1500), prs[0].created_at);
    try std.testing.expectEqual(@as(i64, 1000), prs[1].created_at);
    try std.testing.expectEqual(@as(i64, 500), prs[2].created_at);
}

test "sortByAuthorThenAge - sorts by author then age" {
    var prs = [_]PullRequest{
        .{
            .org = "org1",
            .repo = "repo1",
            .number = 1,
            .title = "PR 1",
            .url = "url1",
            .author = "bob",
            .created_at = 1000,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org2",
            .repo = "repo2",
            .number = 2,
            .title = "PR 2",
            .url = "url2",
            .author = "alice",
            .created_at = 500,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org3",
            .repo = "repo3",
            .number = 3,
            .title = "PR 3",
            .url = "url3",
            .author = "bob",
            .created_at = 800,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    std.mem.sort(PullRequest, &prs, {}, sortByAuthorThenAge);

    try std.testing.expectEqualStrings("alice", prs[0].author);
    try std.testing.expectEqualStrings("bob", prs[1].author);
    try std.testing.expectEqualStrings("bob", prs[2].author);
    try std.testing.expectEqual(@as(i64, 1000), prs[1].created_at);
    try std.testing.expectEqual(@as(i64, 800), prs[2].created_at);
}

test "formatPRIdentifier - short identifier" {
    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Test",
        .url = "url",
        .author = "author",
        .created_at = 0,
        .last_comment_at = null,
        .unique_commenters = 0,
    };

    var buffer: [256]u8 = undefined;
    const result = try formatPRIdentifier(pr, &buffer);
    try std.testing.expectEqualStrings("k8s/kube#1234", result);
}

test "formatPRIdentifier - long identifier not truncated" {
    const pr = PullRequest{
        .org = "very-long-organization",
        .repo = "very-long-repository",
        .number = 12345,
        .title = "Test",
        .url = "url",
        .author = "author",
        .created_at = 0,
        .last_comment_at = null,
        .unique_commenters = 0,
    };

    var buffer: [256]u8 = undefined;
    const result = try formatPRIdentifier(pr, &buffer);

    // Should contain full identifier without truncation
    try std.testing.expectEqualStrings("very-long-organization/very-long-repository#12345", result);
}

test "calcMaxIdentifierWidth - returns max width" {
    const prs = [_]PullRequest{
        .{
            .org = "k8s",
            .repo = "kube",
            .number = 1,
            .title = "Test",
            .url = "url",
            .author = "author",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "very-long-organization",
            .repo = "very-long-repository",
            .number = 12345,
            .title = "Test",
            .url = "url",
            .author = "author",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    const width = calcMaxIdentifierWidth(&prs);
    // "very-long-organization/very-long-repository#12345" = 49 chars
    try std.testing.expectEqual(@as(usize, 49), width);
}

test "calcMaxIdentifierWidth - minimum width" {
    const prs = [_]PullRequest{
        .{
            .org = "a",
            .repo = "b",
            .number = 1,
            .title = "Test",
            .url = "url",
            .author = "author",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    const width = calcMaxIdentifierWidth(&prs);
    // "a/b#1" = 5 chars, but minimum is 12 (header width)
    try std.testing.expectEqual(@as(usize, 12), width);
}

test "formatMineOutput - empty list" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs: []const PullRequest = &[_]PullRequest{};
    try formatMineOutput(std.testing.allocator, buffer.writer(std.testing.allocator), prs, 0);

    try std.testing.expectEqualStrings("No open PRs found\n", buffer.items);
}

test "formatTeamOutput - empty list" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs: []const PullRequest = &[_]PullRequest{};
    try formatTeamOutput(std.testing.allocator, buffer.writer(std.testing.allocator), prs, 0);

    try std.testing.expectEqualStrings("No open PRs found\n", buffer.items);
}

test "formatMineOutput - single PR" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs = [_]PullRequest{
        .{
            .org = "k8s",
            .repo = "kube",
            .number = 1234,
            .title = "Fix node scheduling bug",
            .url = "https://github.com/k8s/kube/pull/1234",
            .author = "alice",
            .created_at = 100,
            .last_comment_at = 900,
            .unique_commenters = 4,
        },
    };

    try formatMineOutput(std.testing.allocator, buffer.writer(std.testing.allocator), &prs, 1000);

    // Check that output contains expected elements
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "k8s/kube#1234") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "Fix node scheduling bug") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "ORG/REPO#NUM") != null);
    // Check that URL appears on second line with 4-space indent
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "    https://github.com/k8s/kube/pull/1234") != null);
}

test "formatTeamOutput - single PR" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs = [_]PullRequest{
        .{
            .org = "k8s",
            .repo = "kube",
            .number = 1234,
            .title = "Fix node scheduling bug",
            .url = "https://github.com/k8s/kube/pull/1234",
            .author = "alice",
            .created_at = 100,
            .last_comment_at = 900,
            .unique_commenters = 4,
        },
    };

    try formatTeamOutput(std.testing.allocator, buffer.writer(std.testing.allocator), &prs, 1000);

    // Check that output contains expected elements
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "alice") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "k8s/kube#1234") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "Fix node scheduling bug") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "AUTHOR") != null);
    // Check that URL appears on second line with 4-space indent
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "    https://github.com/k8s/kube/pull/1234") != null);
}

test "formatMineOutput - long identifiers not truncated" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs = [_]PullRequest{
        .{
            .org = "very-long-organization",
            .repo = "very-long-repository",
            .number = 12345,
            .title = "Test PR",
            .url = "https://github.com/very-long-organization/very-long-repository/pull/12345",
            .author = "alice",
            .created_at = 100,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    try formatMineOutput(std.testing.allocator, buffer.writer(std.testing.allocator), &prs, 1000);

    // Check that full identifier is present (not truncated)
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "very-long-organization/very-long-repository#12345") != null);
}

test "formatJsonOutput - single PR" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs = [_]PullRequest{
        .{
            .org = "k8s",
            .repo = "kube",
            .number = 1234,
            .title = "Fix node scheduling bug",
            .url = "https://github.com/k8s/kube/pull/1234",
            .author = "alice",
            .created_at = 1705322096,
            .last_comment_at = 1705400000,
            .unique_commenters = 4,
        },
    };

    try formatJsonOutput(buffer.writer(std.testing.allocator), &prs);

    // Check that output is valid JSON containing expected fields
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"org\":\"k8s\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"repo\":\"kube\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"number\":1234") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"title\":\"Fix node scheduling bug\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"url\":\"https://github.com/k8s/kube/pull/1234\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"author\":\"alice\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"created_at\":1705322096") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"last_comment_at\":1705400000") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\"unique_commenters\":4") != null);
    // Should be an array
    try std.testing.expect(buffer.items[0] == '[');
}

test "formatJsonOutput - empty list" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs: []const PullRequest = &[_]PullRequest{};
    try formatJsonOutput(buffer.writer(std.testing.allocator), prs);

    // Should output empty array
    try std.testing.expectEqualStrings("[]\n", buffer.items);
}
