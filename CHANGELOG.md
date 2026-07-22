## Upcoming

- feat(tool): add `tool/ai/edit_custom_tracks` resolve helper and Cursor skill for sync `custom_tracks` edits
- fix(library): coerce Engine `AlbumArt.hash` when stored as a raw SHA-1 BLOB (was crashing `library sync engine` with a Uint8List cast error)

## 1.5.0

- feat(export): add `in_phase export spicetify` to write `in-phase-data.js` (Spotify track → Rekordbox Camelot key + BPM) for the spicetify-in-phase extension
- refactor(library): extract `loadRekordboxSongMeta` / `loadRekordboxSongKeys` for shared Rekordbox key+BPM loading (used by `sort` and `export spicetify`)
- feat(sort): preview full Camelot-sorted track list before confirm; grey relative-stable tracks, highlight movers with ↑/↓; quieter fetch logs
- feat(sort): add `in_phase sort` to reorder a Spotify playlist by Rekordbox Camelot keys (1A, 1B, 2A, …); prompts for Y confirmation unless `--yes`
- feat(library): `sync_art` config for `library sync engine` (skip artwork import when false); artwork import shows a clix spinner with `[done/total]` progress
- fix(library): clarify `library sync engine` summary output (`rewritten` vs `up to date`, beat grid write counts)
- feat(library): sync album artwork from Rekordbox `ImagePath` into Engine `AlbumArt` (deduped by SHA-1, external `Artwork/` on schema 3.0.2+)
- fix(library): align beat grid phase and subtract AAC/MP3 encoder delay so Engine downbeats and cues match Rekordbox on WAV and lossy files
- feat(curate): curate playlist argument accepts ID, URI, share URL, or name (exact/fuzzy match in your library)
- feat(curate)!: `targets` in curate config are now a list of playlist identifier strings (ID, URI, URL, or name) instead of `{id, name}` objects; resolved at session start like collect/convert
- feat(curate): press `m` to toggle move mode — keys 1–9 and `f` remove the track from the source playlist (curated playlist or last move target) instead of copying; idempotent when target already has the track
- feat(curate): press `o` to open the current track in Spotify (`spotify://track/…`)
- feat(curate): press `f` to open an add-to-playlist picker (search your library, ↑/↓ to select, Enter to add); user playlists are prefetched at session start
- fix(convert): break tied YouTube text-query matches using YouTube search order
- perf(spotify): fetch offset-paged Spotify resources concurrently via `RequestPool.fetchAllPages` instead of sequential `.all()`
- feat(convert): add `in_phase convert` to match YouTube playlists, videos, or text searches to Spotify tracks
- feat(spotify): find playlists by approximate name in convert, collect, and crawl

## 1.4.1

- ci: run CI and pana only on pull requests, and publish merged `release` PRs with the GitHub Actions `PUB_CREDENTIALS` secret

## 1.4.0

- fix(curate): show API/playback errors in the session log instead of exiting silently; keep curating after playback failures; allow next/quit while a key action is in progress
- perf(curate): use per-track Liked Songs `contains` for `l` instead of waiting for the full library prefetch; load target playlist ids in the background without blocking add-to-target
- feat(curate): replace curate's stream UI with a Nocterm full-screen session (sticky footer with shortcut hints, per-target and Liked Songs indicators, `auto-like: ✓` when enabled); close the Spotify client before Nocterm shuts down
- feat(curate): press `l` to save the current track to Liked Songs; shows an "already in Liked Songs" message when it is already saved (same style as target playlist keys)
- perf(curate): prefetch Liked Songs once per session and update the in-memory id set after each save, so `l` and `auto_add_to_likes` avoid a `contains` API call on every action
- ci: publish releases from merged `release` PRs, add changelog enforcement, and tag successful publishes automatically

## 1.3.1

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
