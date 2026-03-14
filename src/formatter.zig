const std = @import("std");
const time = @import("time.zig");
const github = @import("github.zig");

pub const PullRequest = github.PullRequest;

/// Get terminal width from COLUMNS env var, default 80
pub fn getTerminalWidth() u32 {
    const columns = std.posix.getenv("COLUMNS") orelse return 80;
    return std.fmt.parseInt(u32, columns, 10) catch 80;
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

/// Format org/repo#number with truncation if needed
fn formatPRIdentifier(pr: PullRequest, max_len: usize, buffer: []u8) ![]const u8 {
    var temp_buffer: [256]u8 = undefined;
    const full = try std.fmt.bufPrint(&temp_buffer, "{s}/{s}#{d}", .{ pr.org, pr.repo, pr.number });

    if (full.len <= max_len) {
        @memcpy(buffer[0..full.len], full);
        return buffer[0..full.len];
    }

    // Calculate space for number part - use temp_buffer for calculation
    var number_buffer: [32]u8 = undefined;
    const number_str = try std.fmt.bufPrint(&number_buffer, "#{d}", .{pr.number});

    // Need room for at least "..." + number
    if (max_len < number_str.len + 3) {
        // Not enough space, just show truncated full string
        return truncate(full, max_len, buffer);
    }

    const available_for_org_repo = max_len - number_str.len - 3; // -3 for "..."

    if (available_for_org_repo < 1) {
        // Not enough space, just show truncated number
        return truncate(full, max_len, buffer);
    }

    // Truncate org/repo part
    const org_repo = try std.fmt.bufPrint(&temp_buffer, "{s}/{s}", .{ pr.org, pr.repo });
    const truncated_org_repo = truncate(org_repo, available_for_org_repo, buffer);

    // Add "..." after truncated org/repo
    @memcpy(buffer[truncated_org_repo.len .. truncated_org_repo.len + 3], "...");

    // Combine truncated org/repo with number
    const result_len = truncated_org_repo.len + 3 + number_str.len;
    @memcpy(buffer[truncated_org_repo.len + 3 .. result_len], number_str);

    return buffer[0..result_len];
}

/// Format a single PR row for mine view
fn formatMineRow(
    writer: anytype,
    pr: PullRequest,
    current_time: i64,
    title_width: usize,
) !void {
    var identifier_buffer: [25]u8 = undefined;
    const identifier = try formatPRIdentifier(pr, 25, &identifier_buffer);

    var title_buffer: [1024]u8 = undefined;
    const title = truncate(pr.title, title_width, &title_buffer);

    var age_buffer: [32]u8 = undefined;
    const age = time.formatDuration(current_time - pr.created_at, &age_buffer);

    var last_buffer: [32]u8 = undefined;
    const last = if (pr.last_comment_at) |last_comment|
        time.formatDuration(current_time - last_comment, &last_buffer)
    else
        "-";

    try writer.print("{s: <25}  ", .{identifier});
    // Print title with padding
    try writer.writeAll(title);
    var i: usize = title.len;
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  {s: >5}  {d: >3}  {s: >5}\n", .{
        age,
        pr.unique_commenters,
        last,
    });
}

/// Format a single PR row for team view
fn formatTeamRow(
    writer: anytype,
    pr: PullRequest,
    current_time: i64,
    title_width: usize,
) !void {
    var author_buffer: [8]u8 = undefined;
    const author = truncate(pr.author, 8, &author_buffer);

    var identifier_buffer: [25]u8 = undefined;
    const identifier = try formatPRIdentifier(pr, 25, &identifier_buffer);

    var title_buffer: [1024]u8 = undefined;
    const title = truncate(pr.title, title_width, &title_buffer);

    var age_buffer: [32]u8 = undefined;
    const age = time.formatDuration(current_time - pr.created_at, &age_buffer);

    var last_buffer: [32]u8 = undefined;
    const last = if (pr.last_comment_at) |last_comment|
        time.formatDuration(current_time - last_comment, &last_buffer)
    else
        "-";

    try writer.print("{s: <8}  {s: <25}  ", .{ author, identifier });
    // Print title with padding
    try writer.writeAll(title);
    var i: usize = title.len;
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  {s: >5}  {d: >3}  {s: >5}\n", .{
        age,
        pr.unique_commenters,
        last,
    });
}

/// Sort PRs by age descending (oldest first)
fn sortByAge(_: void, a: PullRequest, b: PullRequest) bool {
    return a.created_at < b.created_at;
}

/// Sort PRs by author then age
fn sortByAuthorThenAge(_: void, a: PullRequest, b: PullRequest) bool {
    const author_cmp = std.mem.order(u8, a.author, b.author);
    if (author_cmp == .eq) {
        return a.created_at < b.created_at;
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

    // Calculate title width
    const terminal_width = getTerminalWidth();
    // Fixed columns: ORG/REPO#NUM(25) + AGE(5) + 👤(3) + LAST(5) + spaces(8) = 46
    const fixed_width: u32 = 46;
    const title_width = if (terminal_width > fixed_width) terminal_width - fixed_width else 20;

    // Print header
    try writer.print("ORG/REPO#NUM             TITLE", .{});
    var i: usize = 0;
    while (i < title_width - 5) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  AGE    👤    LAST\n", .{});

    // Print separator
    i = 0;
    while (i < terminal_width) : (i += 1) {
        try writer.writeAll("─");
    }
    try writer.print("\n", .{});

    // Print rows
    for (sorted_prs) |pr| {
        try formatMineRow(writer, pr, current_time, title_width);
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

    // Calculate title width
    const terminal_width = getTerminalWidth();
    // Fixed columns: AUTHOR(8) + ORG/REPO#NUM(25) + AGE(5) + 👤(3) + LAST(5) + spaces(10) = 56
    const fixed_width: u32 = 56;
    const title_width = if (terminal_width > fixed_width) terminal_width - fixed_width else 20;

    // Print header
    try writer.print("AUTHOR    ORG/REPO#NUM             TITLE", .{});
    var i: usize = 0;
    while (i < title_width - 5) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("  AGE    👤    LAST\n", .{});

    // Print separator
    i = 0;
    while (i < terminal_width) : (i += 1) {
        try writer.writeAll("─");
    }
    try writer.print("\n", .{});

    // Print rows
    for (sorted_prs) |pr| {
        try formatTeamRow(writer, pr, current_time, title_width);
    }
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

test "getTerminalWidth - default when COLUMNS not set" {
    // This will test the default behavior
    // Note: This test may fail if COLUMNS is set in test environment
    const width = getTerminalWidth();
    try std.testing.expect(width >= 80);
}

test "sortByAge - sorts oldest first" {
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

    try std.testing.expectEqual(@as(i64, 500), prs[0].created_at);
    try std.testing.expectEqual(@as(i64, 1000), prs[1].created_at);
    try std.testing.expectEqual(@as(i64, 1500), prs[2].created_at);
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
    try std.testing.expectEqual(@as(i64, 800), prs[1].created_at);
    try std.testing.expectEqual(@as(i64, 1000), prs[2].created_at);
}

test "formatPRIdentifier - no truncation" {
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

    var buffer: [25]u8 = undefined;
    const result = try formatPRIdentifier(pr, 25, &buffer);
    try std.testing.expectEqualStrings("k8s/kube#1234", result);
}

test "formatPRIdentifier - with truncation" {
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

    var buffer: [25]u8 = undefined;
    const result = try formatPRIdentifier(pr, 25, &buffer);

    // Should end with the number
    try std.testing.expect(std.mem.endsWith(u8, result, "#12345"));
    // Should be exactly 25 chars or less
    try std.testing.expect(result.len <= 25);
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
}
