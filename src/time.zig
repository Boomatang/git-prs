const std = @import("std");

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
