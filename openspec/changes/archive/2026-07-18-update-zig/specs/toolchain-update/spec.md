## ADDED Requirements

### Requirement: Build with Zig 0.16.0
The project SHALL compile and pass all tests using Zig 0.16.0 as the minimum supported toolchain version.

#### Scenario: Successful build
- **WHEN** a developer runs `zig build` with Zig 0.16.0 installed
- **THEN** the project compiles without errors

#### Scenario: Tests pass
- **WHEN** a developer runs `zig build test` with Zig 0.16.0 installed
- **THEN** all existing tests pass
