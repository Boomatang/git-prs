## 1. Build System

- [x] 1.1 Modify build.zig to read version and name from build.zig.zon
- [x] 1.2 Create build options module with version and name strings
- [x] 1.3 Pass build options to the executable's root module

## 2. CLI Parsing

- [x] 2.1 Add `version: void` variant to the Command union in cli.zig
- [x] 2.2 Handle `--version` flag in parseArgs (before command parsing, like --help)

## 3. Version Output

- [x] 3.1 Import build_options in main.zig
- [x] 3.2 Add version case to command switch that prints "{name} {version}" and exits

## 4. Testing

- [x] 4.1 Add test for --version flag returning version command
- [x] 4.2 Run zig build test to verify all tests pass
- [x] 4.3 Manual verification: run git_prs --version and confirm output format
