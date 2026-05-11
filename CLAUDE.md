# InPhase

A music library management CLI for creating and syncing playlists between Spotify and Rekordbox.

## Tech Stack

- **Dart 3.10+** — primary language
- **Drift** — SQLite/Database (rekordbox cache)
- **rekorddart** — Rekordbox database access (SQLCipher-encrypted)
- **spotify** ([pub.dev](https://pub.dev/packages/spotify)) — Spotify Web API client
- **doos** — local storage (credentials, config)
- **args** — CLI argument parsing
- **dcli** — terminal colors, utilities
- **nocterm** — curate full-screen TUI (sticky footer, keyboard)
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

Release PRs (changelog + bump `pubspec.yaml` and `Constants.version`, then open a PR): `./tool/prepare_release.sh <x.y.z>` (requires `git`, `gh`, `awk`, clean working tree). Changelog heading logic lives in `tool/rewrite_changelog_for_release.sh`.

Pull requests run GitHub Actions (format, `dart analyze`, tests, coverage upload to Codecov; semantic PR titles; pana). See `.github/workflows/`.

## Code Standards

- Use `dart` (not `fvm dart`) for all Dart commands.
- Use the Dart MCP first; fall back to static analysis if needed.
- Linting: `very_good_analysis`, excludes `**/*.g.dart`, `build/**`.
- Config entities: `@JsonSerializable(fieldRename: FieldRename.snake)`, `yamlDecode` + `YamlMap.toMap()` for YAML.
- Config pattern: Add constant (e.g. `Constants.curateConfigFile`), `fromFile`, default in `config_initializer.dart`.

## Barrel files (`export` barrels)

- **Package entry** — `lib/in_phase.dart` exports only the public CLI surface (`runner.dart`).
- **Cross-cutting barrels** — Prefer importing shared types and helpers through the highest-level barrel that fits:
  - `lib/src/entities/entities.dart` — config models, cache/report entity types
  - `lib/src/misc/misc.dart` — constants, `resolveConfigPath`, `withTeardown`, `rekordboxAudioPath`, etc.
  - `lib/src/spotify/spotify.dart` — Spotify API helpers and ID types
  - `lib/src/database/database.exports.dart` — Drift DB/cache access
  - `lib/src/reports/reports.dart` — report generators
  - `lib/src/crawl/crawl.dart` — crawl pipeline (used by `crawl_command` and crawl internals)
- **CLI** — `lib/src/cli/cli.dart` aggregates CLI wiring. `lib/src/cli/commands/commands.dart` exports **one** library per primary command (e.g. `sync_command.dart`, `curate_command.dart`), not nested subcommand implementation files.
- **Nested command folders** — Subcommands live under `commands/<name>/` (e.g. `cache/`, `curate/`, `sync/`). When a folder exposes multiple modules, add `**commands/<name>/<name>.dart`** as a barrel and import that from the parent command file (e.g. `sync/sync.dart`, `curate/curate.dart`). Keep nested files out of `commands/commands.dart` unless they become a top-level command.

### `package:args` gotcha

A `Command` that registers **subcommands** becomes a **branch command**: the parent’s `run()` is never invoked; the runner requires a subcommand name (e.g. `sync` alone errors with “Missing subcommand”). To support both `**in_phase sync`** (leaf) and `**in_phase sync validate`**, use **rest-argument dispatch** on the parent (e.g. if `argResults.rest.first == 'validate'`) or register `validate` as a separate top-level command.

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

- All new features and changes go in `CHANGELOG.md` under `## Upcoming`.
- New changes are added to the **top** of the list under `## Upcoming`, never the bottom.
- When releasing a new version, the section at the top becomes:
  - `## Upcoming` — then a blank line — then `## <version>` — then a blank line — then the **same** bullet list as before (only headings change; see `tool/rewrite_changelog_for_release.sh`).
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

- [tool/prepare_release.sh](tool/prepare_release.sh) — open a release PR (calls `rewrite_changelog_for_release.sh`, bumps versions, `gh pr create`)
- [tool/rewrite_changelog_for_release.sh](tool/rewrite_changelog_for_release.sh) — rewrite `CHANGELOG.md` headings for a release
- [.github/workflows/](.github/workflows/) — CI workflows (and `publish.yml` for tagged releases)
- [README.md](README.md) — install, setup, usage
- [SYNC_CONFIG.md](docs/SYNC_CONFIG.md) — sync config format
- [CRAWL_CONFIG.md](docs/CRAWL_CONFIG.md) — crawl config format
- [COLLECT_CONFIG.md](docs/COLLECT_CONFIG.md) — collect config format
- [CURATE_CONFIG.md](docs/CURATE_CONFIG.md) — curate config and keyboard controls

