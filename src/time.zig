const std = @import("std");

pub fn parseIso8601Timestamp(iso_string: []const u8) !i64 {
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
/// Get the current date in YYYY-MM-DD format
pub fn getCurrentDate(allocator: std.mem.Allocator) ![]const u8 {
    const timestamp = std.time.timestamp();
    return formatTimestampAsDate(allocator, timestamp);
}

/// Format a Unix timestamp as YYYY-MM-DD
pub fn formatTimestampAsDate(allocator: std.mem.Allocator, timestamp: i64) ![]const u8 {
    const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(timestamp) };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
    });
}

/// Calculate date N days ago from today in YYYY-MM-DD format
pub fn getDateDaysAgo(allocator: std.mem.Allocator, days: u32) ![]const u8 {
    const current_timestamp = std.time.timestamp();
    const seconds_per_day: i64 = 86400;
    const days_ago_timestamp = current_timestamp - (@as(i64, days) * seconds_per_day);
    return formatTimestampAsDate(allocator, days_ago_timestamp);
}

/// Formats a duration in seconds as a human-readable string.
/// Returns a slice into the provided buffer.
pub fn formatDuration(seconds: i64, buffer: []u8) []const u8 {
    const abs_seconds = if (seconds < 0) -seconds else seconds;

    // Less than 1 hour: show minutes
    if (abs_seconds < 3600) {
        const minutes = @divFloor(abs_seconds, 60);
        return std.fmt.bufPrint(buffer, "{d}m", .{minutes}) catch unreachable;
    }

    // 1-23 hours: show hours
    if (abs_seconds < 86400) {
        const hours = @divFloor(abs_seconds, 3600);
        return std.fmt.bufPrint(buffer, "{d}h", .{hours}) catch unreachable;
    }

    // 1-6 days: show days
    if (abs_seconds < 604800) {
        const days = @divFloor(abs_seconds, 86400);
        return std.fmt.bufPrint(buffer, "{d}d", .{days}) catch unreachable;
    }

    // 7-27 days: show weeks
    if (abs_seconds < 2419200) {
        const weeks = @divFloor(abs_seconds, 604800);
        return std.fmt.bufPrint(buffer, "{d}w", .{weeks}) catch unreachable;
    }

    // 28+ days: show months (using 28-day months)
    const months = @divFloor(abs_seconds, 2419200);
    return std.fmt.bufPrint(buffer, "{d}mo", .{months}) catch unreachable;
}

test "formatDuration: 0 seconds" {
    var buffer: [32]u8 = undefined;
    const result = formatDuration(0, &buffer);
    try std.testing.expectEqualStrings("0m", result);
}

test "formatDuration: minutes (< 1 hour)" {
    var buffer: [32]u8 = undefined;

    const result1 = formatDuration(30, &buffer);
    try std.testing.expectEqualStrings("0m", result1);

    const result2 = formatDuration(59, &buffer);
    try std.testing.expectEqualStrings("0m", result2);

    const result3 = formatDuration(60, &buffer);
    try std.testing.expectEqualStrings("1m", result3);

    const result4 = formatDuration(2700, &buffer); // 45 minutes
    try std.testing.expectEqualStrings("45m", result4);

    const result5 = formatDuration(3599, &buffer); // 59 minutes 59 seconds
    try std.testing.expectEqualStrings("59m", result5);
}

test "formatDuration: exactly 1 hour" {
    var buffer: [32]u8 = undefined;
    const result = formatDuration(3600, &buffer);
    try std.testing.expectEqualStrings("1h", result);
}

test "formatDuration: hours (1-23 hours)" {
    var buffer: [32]u8 = undefined;

    const result1 = formatDuration(3600, &buffer); // 1 hour
    try std.testing.expectEqualStrings("1h", result1);

    const result2 = formatDuration(10800, &buffer); // 3 hours
    try std.testing.expectEqualStrings("3h", result2);

    const result3 = formatDuration(86399, &buffer); // 23 hours 59 minutes 59 seconds
    try std.testing.expectEqualStrings("23h", result3);
}

test "formatDuration: exactly 1 day" {
    var buffer: [32]u8 = undefined;
    const result = formatDuration(86400, &buffer);
    try std.testing.expectEqualStrings("1d", result);
}

test "formatDuration: days (1-6 days)" {
    var buffer: [32]u8 = undefined;

    const result1 = formatDuration(86400, &buffer); // 1 day
    try std.testing.expectEqualStrings("1d", result1);

    const result2 = formatDuration(259200, &buffer); // 3 days
    try std.testing.expectEqualStrings("3d", result2);

    const result3 = formatDuration(604799, &buffer); // 6 days 23 hours 59 minutes 59 seconds
    try std.testing.expectEqualStrings("6d", result3);
}

test "formatDuration: exactly 1 week" {
    var buffer: [32]u8 = undefined;
    const result = formatDuration(604800, &buffer);
    try std.testing.expectEqualStrings("1w", result);
}

test "formatDuration: weeks (7-27 days)" {
    var buffer: [32]u8 = undefined;

    const result1 = formatDuration(604800, &buffer); // 1 week (7 days)
    try std.testing.expectEqualStrings("1w", result1);

    const result2 = formatDuration(1209600, &buffer); // 2 weeks (14 days)
    try std.testing.expectEqualStrings("2w", result2);

    const result3 = formatDuration(2419199, &buffer); // 27 days 23 hours 59 minutes 59 seconds
    try std.testing.expectEqualStrings("3w", result3);
}

test "formatDuration: exactly 28 days" {
    var buffer: [32]u8 = undefined;
    const result = formatDuration(2419200, &buffer);
    try std.testing.expectEqualStrings("1mo", result);
}

test "formatDuration: months (28+ days)" {
    var buffer: [32]u8 = undefined;

    const result1 = formatDuration(2419200, &buffer); // 28 days (1 month)
    try std.testing.expectEqualStrings("1mo", result1);

    const result2 = formatDuration(4838400, &buffer); // 56 days (2 months)
    try std.testing.expectEqualStrings("2mo", result2);

    const result3 = formatDuration(7257600, &buffer); // 84 days (3 months)
    try std.testing.expectEqualStrings("3mo", result3);

    const result4 = formatDuration(31536000, &buffer); // ~365 days
    try std.testing.expectEqualStrings("13mo", result4);
}

test "formatDuration: negative durations" {
    var buffer: [32]u8 = undefined;

    const result1 = formatDuration(-3600, &buffer);
    try std.testing.expectEqualStrings("1h", result1);

    const result2 = formatDuration(-86400, &buffer);
    try std.testing.expectEqualStrings("1d", result2);
}

test "getCurrentDate returns YYYY-MM-DD format" {
    const allocator = std.testing.allocator;
    const date = try getCurrentDate(allocator);
    defer allocator.free(date);

    // Should be exactly 10 characters
    try std.testing.expectEqual(@as(usize, 10), date.len);
    // Should have dashes in the right places
    try std.testing.expect(date[4] == '-');
    try std.testing.expect(date[7] == '-');
    // Should be parseable as year-month-day
    _ = std.fmt.parseInt(u16, date[0..4], 10) catch unreachable;
    _ = std.fmt.parseInt(u8, date[5..7], 10) catch unreachable;
    _ = std.fmt.parseInt(u8, date[8..10], 10) catch unreachable;
}

test "formatTimestampAsDate formats correctly" {
    const allocator = std.testing.allocator;
    // Test with Unix epoch: 1970-01-01
    const date = try formatTimestampAsDate(allocator, 0);
    defer allocator.free(date);

    try std.testing.expectEqualStrings("1970-01-01", date);
}

test "formatTimestampAsDate handles various dates" {
    const allocator = std.testing.allocator;

    // Test with a known timestamp: 2024-01-15 12:34:56 UTC
    // This is approximately 1705322096
    const date1 = try formatTimestampAsDate(allocator, 1705322096);
    defer allocator.free(date1);
    try std.testing.expectEqualStrings("2024-01-15", date1);
}

test "getDateDaysAgo returns date N days ago" {
    const allocator = std.testing.allocator;

    // Test that it returns a valid date format
    const date = try getDateDaysAgo(allocator, 7);
    defer allocator.free(date);

    // Should be exactly 10 characters in YYYY-MM-DD format
    try std.testing.expectEqual(@as(usize, 10), date.len);
    try std.testing.expect(date[4] == '-');
    try std.testing.expect(date[7] == '-');
}

test "getDateDaysAgo with 0 days returns today" {
    const allocator = std.testing.allocator;

    const today = try getCurrentDate(allocator);
    defer allocator.free(today);

    const zero_days_ago = try getDateDaysAgo(allocator, 0);
    defer allocator.free(zero_days_ago);

    try std.testing.expectEqualStrings(today, zero_days_ago);
}

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
