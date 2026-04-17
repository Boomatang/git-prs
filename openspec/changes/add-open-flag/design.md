# Design: --open Flag

## Architecture

The `--open` flag integrates as a third output mode alongside table and JSON:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Parse CLI  │────▶│  Fetch PRs  │────▶│   Output    │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                           ┌───────────────────┼───────────┐
                           ▼                   ▼           ▼
                      ┌─────────┐        ┌──────┐    ┌──────┐
                      │  Table  │        │ JSON │    │ Open │
                      └─────────┘        └──────┘    └──────┘
                                                         │
                                                         ▼
                                                ┌─────────────┐
                                                │ xdg-open or │
                                                │ open (macOS)│
                                                └─────────────┘
```

## Components

### 1. CLI Parsing (cli.zig)

Add `open: bool = false` to each args struct:

- `MineArgs`
- `TeamArgs`
- `MergedArgs`

Add `--open` to each command's clap params.

Add validation: `--open` and `--json` together returns `error.OpenWithJson`.

### 2. Browser Module (browser.zig)

New module with a single public function:

```zig
pub fn openUrl(allocator: Allocator, url: []const u8) !void
```

Platform detection at comptime:

```zig
const opener = switch (builtin.os.tag) {
    .linux => "xdg-open",
    .macos => "open",
    else => @compileError("Unsupported OS for --open"),
};
```

Spawns child process, does not wait for completion (browser opens async).

### 3. Command Handlers (main.zig)

Each `run*Command` function checks `args.open` after fetching PRs:

```zig
if (args.open) {
    if (prs.len == 0) {
        try stdout.write("No PRs to open\n");
    } else {
        // Print feedback
        // Open each PR URL
    }
    return;
}
// ... existing table/json output
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| `--open --json` | Parse error: "Cannot use --open with --json" |
| 0 PRs match | Print "No PRs to open", exit 0 |
| Browser spawn fails | Print error to stderr, continue to next URL |
| xdg-open not installed | OS error propagates, user sees failure |

## Testing Strategy

### Unit Tests (cli.zig)

- `--open` flag parsed correctly for each command
- `--open --json` returns `error.OpenWithJson`
- `--open` with other flags (`--org`, `--member`) works

### Integration Tests

- Mock/stub the browser opener for testing
- Verify correct URLs extracted from PR list
- Verify feedback message format

### Manual Testing

- `git_prs team --open` opens correct URLs on Linux
- `git_prs team --open` opens correct URLs on macOS
- `git_prs team --open --json` shows error
