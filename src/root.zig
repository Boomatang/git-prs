//! git-prs - CLI tool for reviewing GitHub pull requests
//! Root source file exposing all modules as a library.

const std = @import("std");

pub const cli = @import("cli.zig");
pub const config = @import("config.zig");
pub const github = @import("github.zig");
pub const formatter = @import("formatter.zig");
pub const time = @import("time.zig");

// Re-export commonly used types
pub const Command = cli.Command;
pub const MineArgs = cli.MineArgs;
pub const TeamArgs = cli.TeamArgs;
pub const Config = config.Config;
pub const PullRequest = github.PullRequest;
pub const Client = github.Client;

test {
    std.testing.refAllDecls(@This());
}
