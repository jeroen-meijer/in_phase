# GitHub Copilot Instructions for InPhase

Before making any suggestions or changes to this codebase, please read the following files to understand the project:

- **[README.md](../README.md)** — Contains installation instructions, setup guide, usage examples, and requirements for the InPhase music library management tool.
- **[CLAUDE.md](../CLAUDE.md)** — Contains technical documentation including tech stack, key directories, common commands, code standards, and project-specific warnings.

## Key Points to Remember

- This is a **Dart 3.10+ CLI tool** for syncing playlists between Spotify and Rekordbox
- Use `dart` (not `fvm dart`) for all Dart commands
- Never suggest running expensive API commands (`sync`, `crawl`, etc.) without explicit permission
- Never suggest clearing caches or deleting data from Spotify or Rekordbox
- Follow the code standards defined in CLAUDE.md (linting with `very_good_analysis`, JSON serialization patterns, config patterns)
- Config files live in `~/.in_phase/`
- The project uses Drift for SQLite/database, rekorddart for Rekordbox access, and spotify-dart for Spotify API

## Changelog Workflow

When updating CHANGELOG.md:

- All new features and changes go under `## Upcoming`
- **Add new changes to the TOP of the list** under `## Upcoming`, never the bottom
- Use conventional commit format: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, etc.
- Include scope in parentheses when relevant: `feat(crawl):`, `fix(cache):`, etc.
- When releasing: replace `## Upcoming` with `## <version>`, add new `## Upcoming` above it with an empty line between

## Additional Documentation

- [SYNC_CONFIG.md](../SYNC_CONFIG.md) — Sync configuration format
- [CRAWL_CONFIG.md](../CRAWL_CONFIG.md) — Crawl configuration format  
- [COLLECT_CONFIG.md](../COLLECT_CONFIG.md) — Collect configuration format
- [CURATE_CONFIG.md](../CURATE_CONFIG.md) — Curate configuration and keyboard controls
