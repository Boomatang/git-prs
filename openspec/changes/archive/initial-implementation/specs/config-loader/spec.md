## ADDED Requirements

### Requirement: Load config from XDG location
The config loader SHALL read configuration from `~/.config/git-prs/config.json`.

#### Scenario: Config file exists and is valid
- **WHEN** config file exists with valid JSON structure
- **THEN** config loader returns parsed Config struct with mine_orgs and teams populated

#### Scenario: Config file does not exist
- **WHEN** config file is missing
- **THEN** config loader exits with error "Config not found. Create ~/.config/git-prs/config.json" and shows example format

#### Scenario: Config file is invalid JSON
- **WHEN** config file contains invalid JSON syntax
- **THEN** config loader exits with error "Invalid config: {parse error details}"

### Requirement: Validate config structure
The config loader SHALL validate required fields and structure.

#### Scenario: Missing mine.orgs
- **WHEN** config file has no mine.orgs array or it is empty
- **THEN** config loader exits with error "Config error: mine.orgs must contain at least one org"

#### Scenario: Empty org name in mine.orgs
- **WHEN** config file has mine.orgs containing an empty string
- **THEN** config loader exits with error "Config error: mine.orgs contains empty org name"

#### Scenario: Empty team member list
- **WHEN** config file has a team with an empty member array
- **THEN** config loader exits with error "Config error: team.{org} has no members listed"

#### Scenario: Missing team section
- **WHEN** config file has no team section
- **THEN** config loader allows it; team command will error at runtime with "No teams configured"

### Requirement: Obtain auth token from gh CLI
The config loader SHALL obtain the GitHub auth token by running `gh auth token`.

#### Scenario: gh CLI returns token
- **WHEN** `gh auth token` succeeds
- **THEN** config loader captures the token and includes it in Config struct

#### Scenario: gh CLI not installed
- **WHEN** `gh` command is not found
- **THEN** config loader exits with error "gh CLI not found. Install from https://cli.github.com"

#### Scenario: gh auth token fails
- **WHEN** `gh auth token` returns non-zero exit code
- **THEN** config loader exits with error "Not authenticated. Run `gh auth login` first"

### Requirement: Obtain authenticated username
The config loader SHALL obtain the authenticated user's GitHub username by calling the GitHub `/user` endpoint.

#### Scenario: User endpoint succeeds
- **WHEN** GitHub API `/user` returns user data
- **THEN** config loader extracts login field and includes it in Config struct as authenticated_user

#### Scenario: User endpoint fails
- **WHEN** GitHub API `/user` returns an error
- **THEN** config loader exits with error "Failed to get authenticated user: {details}"
