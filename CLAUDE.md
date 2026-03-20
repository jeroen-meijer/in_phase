# InPhase

A music library management CLI for creating and syncing playlists between Spotify and Rekordbox.

## Tech Stack

- **Dart 3.10+** — primary language
- **Drift** — SQLite/Database (rekordbox cache)
- **rekorddart** — Rekordbox database access (SQLCipher-encrypted)
- **spotify-dart** — Spotify Web API client
- **doos** — local storage (credentials, config)
- **args** — CLI argument parsing
- **dcli** — terminal colors, utilities
- **very_good_analysis** — lint rules

## Key Directories

```
bin/                    # Entry point (bin/in_phase.dart)
lib/src/
├── cli/               # CLI runner, command registration
│   ├── commands/      # All commands (sync, crawl, curate, login, etc.)
│   └── cli_dependencies.dart  # runWithCliDependencies, Env, Doos
├── crawl/             # Crawl logic (track collection, dedup, cover gen)
├── database/         # Drift schemas, daos (cache)
├── entities/         # Config entities (sync, crawl, curate) + JSON serialization
├── logger/           # Structured logging
├── misc/              # Constants, config init, time_utils, with_teardown
├── reports/           # Sync/crawl report generation
├── spotify/           # OAuth, API wrapper, types, playlist ID parsing
└── ...
```

## Common Commands

```bash
dart pub get
./run.sh <command>           # Builds if needed, then runs in_phase
dart run bin/in_phase.dart <command>
dart run build_runner build --delete-conflicting-outputs
dart test
```

## Code Standards

- Use `dart` (not `fvm dart`) for all Dart commands.
- Use the Dart MCP first; fall back to static analysis if needed.
- Linting: `very_good_analysis`, excludes `**/*.g.dart`, `build/**`.
- Config entities: `@JsonSerializable(fieldRename: FieldRename.snake)`, `yamlDecode` + `YamlMap.toMap()` for YAML.
- Config pattern: Add constant (e.g. `Constants.curateConfigFile`), `fromFile`, default in `config_initializer.dart`.

## Git Conventions

### Branch Naming

- Feature branches: `feat/<description>` (e.g., `feat/api-refactor-for-app`)
- Bug fixes: `fix/<description>` (e.g., `fix/spotify-api-compliance`)
- Copilot branches: `copilot/<description>` (e.g., `copilot/featinclude-tracks-in-crawl`)

### Commit Messages

Follow conventional commits format: `<type>[optional scope]: <description>`

**Types:**
- `feat`: New feature (e.g., `feat(crawl): add flexible date_range filter`)
- `fix`: Bug fix (e.g., `fix(request-pool): respect Retry-After from Spotify 429 responses`)
- `refactor`: Code refactoring (e.g., `refactor(crawl): move target_playlist to output_playlist.id`)
- `chore`: Maintenance tasks (e.g., `chore: prepare release v1.2.0`)
- `docs`: Documentation changes (e.g., `docs: update docs and/or version file`)
- `style`: Formatting changes (e.g., `style: format all files`)
- `ci`: CI/CD changes (e.g., `ci: add publish script`)

**Scopes:** Use when relevant (e.g., `crawl`, `cache`, `curate`, `request-pool`, `collect`)

## Changelog Workflow

- All new features and changes go in CHANGELOG.md under `## Upcoming`.
- New changes are added to the **top** of the list under `## Upcoming`, never the bottom.
- When releasing a new version:
  - Replace `## Upcoming` with `## <version>`
  - Add a new `## Upcoming` section above it with an empty newline in between
  - Do not modify the actual change lines, only the headings
- Before committing:
  - Run `dart format .` and `dart analyze --fatal-infos --fatal-warnings .`
  - If there are errors, fix them and rerun both commands
  - Repeat in a loop until all errors are fixed
  - If you encounter errors you cannot fix, HALT and report them

## Project-Specific Warnings

- **Never run `sync`, `crawl`, etc. yourself** — always ask for permission. These are expensive API calls; avoid rate limits.
- **Never clear the cache** for crawl or sync without permission.
- **Never run commands or scripts that delete data** from Spotify or Rekordbox.
- Config lives in `~/.in_phase/`. Use `in_phase config reveal` to open it.
- Curate command is Spotify-only; no Rekordbox needed.

## Documentation

- [README.md](README.md) — install, setup, usage
- [SYNC_CONFIG.md](SYNC_CONFIG.md) — sync config format
- [CRAWL_CONFIG.md](CRAWL_CONFIG.md) — crawl config format
- [COLLECT_CONFIG.md](COLLECT_CONFIG.md) — collect config format
- [CURATE_CONFIG.md](CURATE_CONFIG.md) — curate config and keyboard controls
