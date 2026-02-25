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
- [CURATE_CONFIG.md](CURATE_CONFIG.md) — curate config and keyboard controls
