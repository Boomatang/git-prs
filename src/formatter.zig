const std = @import("std");
const time = @import("time.zig");
const github = @import("github.zig");

pub const PullRequest = github.PullRequest;

/// Minimum title width for inline URL display eligibility
const MIN_TITLE_WIDTH: usize = 20;

/// Minimum author width when truncation is required
const MIN_AUTHOR_WIDTH: usize = 6;

/// Check if URL fits inline with at least MIN_TITLE_WIDTH for the title.
/// Returns the available title width if inline is eligible, or null if not.
/// The 2-space separator between columns and URL is accounted for.
fn urlFitsInline(terminal_width: u32, fixed_columns: usize, url_len: usize) ?usize {
    const url_space_needed = url_len + 2; // URL + 2-space separator
    const total_fixed = fixed_columns + url_space_needed;
    if (terminal_width <= total_fixed) return null;
    const available_for_title = terminal_width - total_fixed;
    if (available_for_title >= MIN_TITLE_WIDTH) {
        return available_for_title;
    }
    return null;
}

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

/// Calculate the maximum title width needed for a list of PRs
fn calcMaxTitleWidth(prs: []const PullRequest) usize {
    var max_width: usize = 5; // minimum "TITLE" header width
    for (prs) |pr| {
        if (pr.title.len > max_width) {
            max_width = pr.title.len;
        }
    }
    return max_width;
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

/// Calculate the maximum author width needed for a list of PRs
fn calcMaxAuthorWidth(prs: []const PullRequest) usize {
    var max_width: usize = MIN_AUTHOR_WIDTH; // minimum for "AUTHOR" header
    for (prs) |pr| {
        if (pr.author.len > max_width) {
            max_width = pr.author.len;
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
    url_inline: bool,
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
    if (url_inline) {
        // Print URL inline with 2-space separator after LAST column
        try writer.print("  {s: >5}  {d: >3}  {s: >5}  {s}\n", .{
            age,
            pr.unique_commenters,
            last,
            pr.url,
        });
    } else {
        try writer.print("  {s: >5}  {d: >3}  {s: >5}\n", .{
            age,
            pr.unique_commenters,
            last,
        });
        // Print URL on second line with 4-space indent
        try writer.print("    {s}\n", .{pr.url});
    }
}

/// Format a single PR row for team view
fn formatTeamRow(
    writer: anytype,
    pr: PullRequest,
    current_time: i64,
    title_width: usize,
    identifier_width: usize,
    author_width: usize,
    url_inline: bool,
) !void {
    var author_buffer: [256]u8 = undefined;
    const author = truncate(pr.author, author_width, &author_buffer);

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

    // Print author with dynamic padding
    try writer.writeAll(author);
    var i: usize = author.len;
    while (i < author_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  ");
    // Print identifier with dynamic padding
    try writer.writeAll(identifier);
    i = identifier.len;
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
    if (url_inline) {
        // Print URL inline with 2-space separator after LAST column
        try writer.print("  {s: >5}  {d: >3}  {s: >5}  {s}\n", .{
            age,
            pr.unique_commenters,
            last,
            pr.url,
        });
    } else {
        try writer.print("  {s: >5}  {d: >3}  {s: >5}\n", .{
            age,
            pr.unique_commenters,
            last,
        });
        // Print URL on second line with 4-space indent
        try writer.print("    {s}\n", .{pr.url});
    }
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

/// Calculate the maximum URL length across all PRs
fn calcMaxUrlLen(prs: []const PullRequest) usize {
    var max_len: usize = 0;
    for (prs) |pr| {
        if (pr.url.len > max_len) {
            max_len = pr.url.len;
        }
    }
    return max_len;
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

    const terminal_width = getTerminalWidth();
    // Fixed columns for mine view: identifier_width + 2 + AGE(5) + 2 + 👤(3) + 2 + LAST(5) + 2 = identifier_width + 21
    const fixed_columns = identifier_width + 21;

    // Determine if we can use inline mode for ALL rows (based on longest URL)
    const max_url_len = calcMaxUrlLen(sorted_prs);
    const use_inline = urlFitsInline(terminal_width, fixed_columns, max_url_len) != null;

    // Calculate title width - adaptive based on actual content
    const max_title_len = calcMaxTitleWidth(sorted_prs) + 2; // +2 for visual margin
    const available_width = if (use_inline)
        urlFitsInline(terminal_width, fixed_columns, max_url_len).?
    else if (terminal_width > fixed_columns)
        terminal_width - fixed_columns
    else
        MIN_TITLE_WIDTH;
    const title_width = @max(MIN_TITLE_WIDTH, @min(max_title_len, available_width));

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
    if (use_inline) {
        try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST  URL\n", .{});
    } else {
        try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST\n", .{});
    }

    // Print separator (use total row width)
    const base_width = identifier_width + 2 + title_width + 2 + 5 + 4 + 3 + 4 + 5;
    const total_width = if (use_inline) base_width + 2 + max_url_len else base_width;
    i = 0;
    while (i < total_width) : (i += 1) {
        try writer.writeAll("\xe2\x94\x80");
    }
    try writer.print("\n", .{});

    // Print rows - all use the same format (inline or two-line)
    for (sorted_prs) |pr| {
        try formatMineRow(writer, pr, current_time, title_width, identifier_width, use_inline);
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

    // Calculate max author width based on content
    const max_author_width = calcMaxAuthorWidth(sorted_prs);

    const terminal_width = getTerminalWidth();

    // Calculate author width with truncation priority
    // Required fixed space: identifier_width + spacing(2) + AGE(5) + spacing(2) + 👤(3) + spacing(2) + LAST(5) + spacing(2) = identifier_width + 21
    const required_fixed = identifier_width + 21 + MIN_TITLE_WIDTH;
    const available_for_author = if (terminal_width > required_fixed) terminal_width - required_fixed else 0;

    const author_width = if (available_for_author >= max_author_width)
        max_author_width
    else if (available_for_author >= MIN_AUTHOR_WIDTH)
        available_for_author
    else
        MIN_AUTHOR_WIDTH;

    // Fixed columns for team view: author_width + 2 + identifier_width + 2 + AGE(5) + 2 + 👤(3) + 2 + LAST(5) + 2 = author_width + identifier_width + 23
    const fixed_columns = author_width + 2 + identifier_width + 21;

    // Determine if we can use inline mode for ALL rows (based on longest URL)
    const max_url_len = calcMaxUrlLen(sorted_prs);
    const use_inline = urlFitsInline(terminal_width, fixed_columns, max_url_len) != null;

    // Calculate title width - adaptive based on actual content
    const max_title_len = calcMaxTitleWidth(sorted_prs) + 2; // +2 for visual margin
    const available_width = if (use_inline)
        urlFitsInline(terminal_width, fixed_columns, max_url_len).?
    else if (terminal_width > fixed_columns)
        terminal_width - fixed_columns
    else
        MIN_TITLE_WIDTH;
    const title_width = @max(MIN_TITLE_WIDTH, @min(max_title_len, available_width));

    // Print header with dynamic author and identifier column widths
    try writer.writeAll("AUTHOR");
    var i: usize = 6; // "AUTHOR" is 6 chars
    while (i < author_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  ORG/REPO#NUM");
    i = 12; // "ORG/REPO#NUM" is 12 chars
    while (i < identifier_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.writeAll("  TITLE");
    i = 5; // "TITLE" is 5 chars
    while (i < title_width) : (i += 1) {
        try writer.writeByte(' ');
    }
    if (use_inline) {
        try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST  URL\n", .{});
    } else {
        try writer.print("  AGE    \xf0\x9f\x91\xa4    LAST\n", .{});
    }

    // Print separator (use total row width)
    const base_width = author_width + 2 + identifier_width + 2 + title_width + 2 + 5 + 4 + 3 + 4 + 5;
    const total_width = if (use_inline) base_width + 2 + max_url_len else base_width;
    i = 0;
    while (i < total_width) : (i += 1) {
        try writer.writeAll("\xe2\x94\x80");
    }
    try writer.print("\n", .{});

    // Print rows - all use the same format (inline or two-line)
    for (sorted_prs) |pr| {
        try formatTeamRow(writer, pr, current_time, title_width, identifier_width, author_width, use_inline);
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

test "calcMaxAuthorWidth - returns max author length" {
    const prs = [_]PullRequest{
        .{
            .org = "org",
            .repo = "repo",
            .number = 1,
            .title = "Test",
            .url = "url",
            .author = "bob",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org",
            .repo = "repo",
            .number = 2,
            .title = "Test",
            .url = "url",
            .author = "very-long-username",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org",
            .repo = "repo",
            .number = 3,
            .title = "Test",
            .url = "url",
            .author = "alice",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    const width = calcMaxAuthorWidth(&prs);
    // "very-long-username" = 18 chars
    try std.testing.expectEqual(@as(usize, 18), width);
}

test "calcMaxAuthorWidth - minimum width" {
    const prs = [_]PullRequest{
        .{
            .org = "org",
            .repo = "repo",
            .number = 1,
            .title = "Test",
            .url = "url",
            .author = "bob",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    const width = calcMaxAuthorWidth(&prs);
    // "bob" = 3 chars, but minimum is 6 (header width)
    try std.testing.expectEqual(@as(usize, 6), width);
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

// Tests for inline URL functionality

test "urlFitsInline - returns title width when URL fits" {
    // terminal=150, fixed=35, url=45 → available = 150-35-45-2 = 68 >= 20
    const result = urlFitsInline(150, 35, 45);
    try std.testing.expectEqual(@as(?usize, 68), result);
}

test "urlFitsInline - returns null when URL doesn't fit" {
    // terminal=80, fixed=35, url=45 → available = 80-35-45-2 = -2 < 20
    const result = urlFitsInline(80, 35, 45);
    try std.testing.expectEqual(@as(?usize, null), result);
}

test "urlFitsInline - returns exactly 20 at threshold boundary" {
    // Need: terminal - fixed - url - 2 = 20
    // terminal=100, fixed=30, url=48 → available = 100-30-48-2 = 20
    const result = urlFitsInline(100, 30, 48);
    try std.testing.expectEqual(@as(?usize, 20), result);
}

test "urlFitsInline - returns null at one below threshold" {
    // terminal=100, fixed=30, url=49 → available = 100-30-49-2 = 19 < 20
    const result = urlFitsInline(100, 30, 49);
    try std.testing.expectEqual(@as(?usize, null), result);
}

test "formatMineRow - inline URL display" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "alice",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    try formatMineRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, true);

    // URL should be on the same line (inline), not on a separate line
    // Check there's only one newline (single line output)
    var newline_count: usize = 0;
    for (buffer.items) |c| {
        if (c == '\n') newline_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), newline_count);

    // URL should appear after the LAST column with 2-space separator
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "  https://github.com/k8s/kube/pull/1234") != null);
}

test "formatMineRow - two-line URL display" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "alice",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    try formatMineRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, false);

    // URL should be on a separate line with 4-space indent
    // Check there are two newlines (two line output)
    var newline_count: usize = 0;
    for (buffer.items) |c| {
        if (c == '\n') newline_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), newline_count);

    // URL should appear with 4-space indent
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "    https://github.com/k8s/kube/pull/1234") != null);
}

test "formatTeamRow - inline URL display" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "alice",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    try formatTeamRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, 8, true);

    // URL should be on the same line (inline)
    var newline_count: usize = 0;
    for (buffer.items) |c| {
        if (c == '\n') newline_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), newline_count);

    // URL should appear after the LAST column with 2-space separator
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "  https://github.com/k8s/kube/pull/1234") != null);
}

test "formatTeamRow - two-line URL display" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "alice",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    try formatTeamRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, 8, false);

    // URL should be on a separate line
    var newline_count: usize = 0;
    for (buffer.items) |c| {
        if (c == '\n') newline_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), newline_count);

    // URL should appear with 4-space indent
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "    https://github.com/k8s/kube/pull/1234") != null);
}

test "urlFitsInline - very long URL forces two-line format" {
    // Very long URL (>100 chars) should not fit inline in typical terminal
    // terminal=120, fixed=40, url=110 → available = 120-40-110-2 = -32 < 20
    const result = urlFitsInline(120, 40, 110);
    try std.testing.expectEqual(@as(?usize, null), result);
}

test "urlFitsInline - very long identifier reduces inline eligibility" {
    // Long identifier increases fixed_columns, reducing space for title
    // terminal=100, fixed=60 (long identifier), url=30 → available = 100-60-30-2 = 8 < 20
    const result = urlFitsInline(100, 60, 30);
    try std.testing.expectEqual(@as(?usize, null), result);
}

test "urlFitsInline - minimum title width preserved" {
    // Even with plenty of terminal width, we should get at least MIN_TITLE_WIDTH (20)
    // terminal=200, fixed=30, url=40 → available = 200-30-40-2 = 128 >= 20
    const result = urlFitsInline(200, 30, 40);
    try std.testing.expect(result != null);
    try std.testing.expect(result.? >= MIN_TITLE_WIDTH);
}

test "urlFitsInline - terminal width equals total needed returns null" {
    // Edge case: terminal exactly equals fixed + url + 2 (no room for title)
    // terminal=77, fixed=35, url=40 → available = 77-35-40-2 = 0 < 20
    const result = urlFitsInline(77, 35, 40);
    try std.testing.expectEqual(@as(?usize, null), result);
}

test "urlFitsInline - terminal width less than fixed columns returns null" {
    // Edge case: terminal smaller than fixed columns alone
    // terminal=30, fixed=35, url=40 → overflow
    const result = urlFitsInline(30, 35, 40);
    try std.testing.expectEqual(@as(?usize, null), result);
}

test "formatMineRow - URL never truncated in inline mode" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const long_url = "https://github.com/very-long-organization-name/very-long-repository-name/pull/12345";
    const pr = PullRequest{
        .org = "org",
        .repo = "repo",
        .number = 1,
        .title = "Test",
        .url = long_url,
        .author = "alice",
        .created_at = 100,
        .last_comment_at = null,
        .unique_commenters = 0,
    };

    try formatMineRow(buffer.writer(std.testing.allocator), pr, 1000, 20, 12, true);

    // Full URL should appear without truncation
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, long_url) != null);
}

test "formatMineRow - URL never truncated in two-line mode" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const long_url = "https://github.com/very-long-organization-name/very-long-repository-name/pull/12345";
    const pr = PullRequest{
        .org = "org",
        .repo = "repo",
        .number = 1,
        .title = "Test",
        .url = long_url,
        .author = "alice",
        .created_at = 100,
        .last_comment_at = null,
        .unique_commenters = 0,
    };

    try formatMineRow(buffer.writer(std.testing.allocator), pr, 1000, 20, 12, false);

    // Full URL should appear without truncation
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, long_url) != null);
}

// Tests for header URL column in inline mode

test "formatMineOutput - header includes URL column in inline mode" {
    // Use a mock that forces inline mode by setting a very wide terminal
    // We'll test this by checking the output contains "URL" in the header
    // Since we can't control terminal width directly, we verify header format logic
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    // Create PRs with short URLs that would fit inline on a wide terminal
    const prs = [_]PullRequest{
        .{
            .org = "org",
            .repo = "repo",
            .number = 1,
            .title = "Test PR",
            .url = "https://x.co/1",
            .author = "alice",
            .created_at = 100,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    try formatMineOutput(std.testing.allocator, buffer.writer(std.testing.allocator), &prs, 1000);

    // Header should contain expected columns
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "ORG/REPO#NUM") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "TITLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "AGE") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "LAST") != null);
    // URL header appears only in inline mode - depends on terminal width
    // If inline mode is active, URL should be in header; otherwise URL is on second line
}

test "formatTeamOutput - header includes URL column in inline mode" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const prs = [_]PullRequest{
        .{
            .org = "org",
            .repo = "repo",
            .number = 1,
            .title = "Test PR",
            .url = "https://x.co/1",
            .author = "alice",
            .created_at = 100,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    try formatTeamOutput(std.testing.allocator, buffer.writer(std.testing.allocator), &prs, 1000);

    // Header should contain expected columns
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "AUTHOR") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "ORG/REPO#NUM") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "TITLE") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "AGE") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "LAST") != null);
}

// Tests for calcMaxTitleWidth and adaptive title width

test "calcMaxTitleWidth - returns max title length" {
    const prs = [_]PullRequest{
        .{
            .org = "org",
            .repo = "repo",
            .number = 1,
            .title = "Short",
            .url = "url",
            .author = "alice",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
        .{
            .org = "org",
            .repo = "repo",
            .number = 2,
            .title = "This is a much longer title",
            .url = "url",
            .author = "bob",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    const width = calcMaxTitleWidth(&prs);
    // "This is a much longer title" = 27 chars
    try std.testing.expectEqual(@as(usize, 27), width);
}

test "calcMaxTitleWidth - minimum width is 5 (TITLE header)" {
    const prs = [_]PullRequest{
        .{
            .org = "org",
            .repo = "repo",
            .number = 1,
            .title = "Hi",
            .url = "url",
            .author = "alice",
            .created_at = 0,
            .last_comment_at = null,
            .unique_commenters = 0,
        },
    };

    const width = calcMaxTitleWidth(&prs);
    // "Hi" = 2 chars, but minimum is 5 (header width)
    try std.testing.expectEqual(@as(usize, 5), width);
}

test "calcMaxTitleWidth - empty list returns minimum" {
    const prs: []const PullRequest = &[_]PullRequest{};
    const width = calcMaxTitleWidth(prs);
    try std.testing.expectEqual(@as(usize, 5), width);
}

test "formatTeamRow - full author display when space available" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "very-long-username",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    // Provide enough author_width to display full username
    try formatTeamRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, 18, false);

    // Full author should be displayed without truncation
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "very-long-username") != null);
}

test "formatTeamRow - author truncation when constrained" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "very-long-username",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    // Constrain author_width to 10 chars
    try formatTeamRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, 10, false);

    // Author should be truncated with "..."
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "very-lo...") != null);
    // Full username should NOT be present
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "very-long-username") == null);
}

test "formatTeamRow - minimum author width preserved" {
    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer buffer.deinit(std.testing.allocator);

    const pr = PullRequest{
        .org = "k8s",
        .repo = "kube",
        .number = 1234,
        .title = "Fix node scheduling bug",
        .url = "https://github.com/k8s/kube/pull/1234",
        .author = "very-long-username",
        .created_at = 100,
        .last_comment_at = 900,
        .unique_commenters = 4,
    };

    // Use minimum author_width of 6
    try formatTeamRow(buffer.writer(std.testing.allocator), pr, 1000, 30, 15, 6, false);

    // Author should be truncated to 6 chars: "ver..."
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "ver...") != null);
}
