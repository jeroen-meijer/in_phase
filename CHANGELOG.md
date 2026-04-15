## Upcoming

- ci: cache ci setup steps
- chore: rename 'docs' directory to 'doc'
- feat(crawl): add optional `cover.font` to render covers with ImageMagick using custom TTF/OTF fonts, with automatic fallback to Dart-native rendering when ImageMagick is unavailable or fails
- docs(crawl): document custom cover font usage and update crawl config/default schema examples

## 1.3.0

- chore(tool): `prepare_release.sh` and `rewrite_changelog_for_release.sh` (`awk`/`sed`); add Pana CI workflow
- docs: README contributing/CI; CLAUDE tech stack `spotify` pub package; Copilot instructions link workflows
- fix(cli): resolve relative config paths to absolute after tilde expansion; clarify config path test name
- chore(deps): use `spotify: ^0.16.1` from pub instead of a git dependency
- ci: upload coverage to Codecov (OSS); analyze full repository; ignore `coverage/`
- feat(collect): per-collection `track_order` (`oldest_first` | `newest_first`, default `oldest_first`) to sort the target playlist by `added_at`
- refactor(crawl): remove `{time_format_HH_MM}` template variable (was always `00:00` for date-only crawl end; use `{real_time}` for wall-clock time)
- refactor(crawl): use `simple_date` (`SimpleDate`) for date-only ranges, parsing, and filters; align playlist release vs added-day checks with calendar-day helpers
- feat(curate): optional `auto_add_to_likes` in curate config — saves to Liked Songs when adding to a target playlist; shows "Liked" only if the track was not already saved
- fix(sync): route `sync validate` via first rest argument instead of an `args` subcommand so `in_phase sync` and `in_phase sync <playlist>…` work again (`--config` only applies to validate)
- feat(search): show audio file path in track details when looking up by Rekordbox ID (above Cues)
- fix(sync): `sync validate` runs Spotify playlist checks concurrently via `RequestPool` and prints grouped, color-balanced issue sections with truncated paths
- refactor(sync): centralize sync config YAML parsing (`SyncConfig.fromYamlString`)
- chore: add Rekordbox audio path helper (`rekordboxAudioPath`)
- docs: document barrel-file conventions in `CLAUDE.md`
- feat(sync): add `sync validate` to check sync config YAML, Spotify playlist keys in `custom_tracks`, and Rekordbox track IDs with on-disk audio files
- feat(curate): press `c` to copy the current track's Spotify URL to the clipboard
- feat(sync): add interactive `buy` command to open iTunes links for missing tracks
- fix(cli): resolve `~` and relative paths passed via `-c/--config` to absolute paths
- fix(cli): stop creating new config files when a custom `-c/--config` path does not exist
- feat(crawl): include artist appearances on albums and compilations in crawl
- fix(request-pool): respect Retry-After from Spotify 429 responses
- fix(crawl): use `api.me.playlists.create` instead of `api.playlists.createPlaylist`
- fix(crawl): fix some albums not being found by sorting artist's albums by release date
- feat(cache): add `cache clear-artists` command to delete cached albums for specific artists
- fix: decrease album fetch limit to 10 (according to Spotify API docs)
- fix(crawl): include time in `realDateTime` and `realDateTimeFull` template variables
- refactor(crawl): move `target_playlist` to `output_playlist.id` (breaking config change)
- refactor(crawl): remove deprecated `append_to_existing` option in favor of `target_playlist` + `update_mode`
- feat(crawl): add `update_mode` option (`replace` or `append`) for controlling how target playlists are updated
- feat(crawl): add `target_playlist` option to update existing playlists instead of creating new ones
- refactor(crawl): use barrel imports for crawl module
- feat(crawl): add `date_range: "today"` shortcut for single-day filtering
- feat(crawl): deprecate `added_between_days` in favor of `date_range` (backward compatible)
- feat(crawl): add flexible `date_range` filter supporting current month/week/year, time units (days/weeks/months), and absolute date ranges

## 1.2.0

- feat(collect): add `collect` command to aggregate tracks from multiple Spotify playlists into a single target playlist
- feat(crawl): add in-place TUI with parallel collection, progress display, slots for active sources, recently completed section, spinner and checkmarks, fall back to log output when not a TTY
- refactor(curate): extract command into curate/ module (types, key handler, display) for maintainability
- fix(curate): stop re-printing "Added to" status when pressing N after adding a track
- chore: adopt recursive barrel files (crawl, curate, reports) and update imports to use highest available barrel

## 1.1.5

- feat: add `curate` command to preview playlist tracks and organize them into target playlists
- fix: remove invalid sync cache mappings when Rekordbox track was deleted
- fix: exit search after initial query instead of entering interactive mode

## 1.1.4

- feat: add `update` command to update InPhase to the latest version
- docs: expand Rekordbox setup instructions with comprehensive rekorddart prerequisites
- chore: update rekorddart to 1.1.1 (use default encryption key when REKORDBOX_DB_KEY is not set)

## 1.1.3

- feat: add `cache clean` command to delete build folder containing sync and crawl reports
- feat: automatically initialize default config files with helpful examples on first run
- chore: remove unused constants (`syncCacheFile`, `crawlCacheFile`)

## 1.1.2

- feat: improved YouTube channel source reporting in crawl reports
- docs: update documentation to include YouTube channel configuration

## 1.1.1

- feat: add support for YouTube channel sources to crawl command
- ci: add publish script

## 1.1.0

- feat: add search command and cues sync functionality
- docs: document rekorddart setup prerequisite for Rekordbox features
- chore: upgrade to dart 3.10
- feat: add config reveal command to open config directory
- chore: remove local dependencies in favor of git and pub hosted
- chore: improve docs, remove old export file
- chore: rename project to in_phase
- chore: database migrations, minor edits
- refactor: migrate to Drift, generate sync reports
- feat: cache more stuff
- feat: make reports on every crawl run
- feat: enhance logging and debugging for track collection and request handling
- feat: add custom track support for playlist sync operations
- feat: add crawl command, improve sync caching
- docs: add comprehensive configuration documentation

## 1.0.0

- Initial version.
