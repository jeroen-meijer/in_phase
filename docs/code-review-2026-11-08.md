# Code review 2026-11-08

Review of the whole repository at `5d06c5b` (branch `fix/curate-playback-start-position`, two commits ahead of `main`). Scope: `lib/`, `bin/`, `test/`, `tool/`, CI config and docs. Baseline before any change: `dart analyze --fatal-infos --fatal-warnings .` is clean, `dart format` changes nothing, and all 111 tests pass.

Each finding has an ID, a severity, where it lives, what goes wrong, and the planned fix. Severity:

- **high**: crashes, data loss, or a command that cannot run for a normal user
- **medium**: wrong results in realistic cases, or a structural problem that keeps causing bugs
- **low**: smaller bugs, dead code, duplication, misleading docs

The fix plan at the end lists the order of work and what each fix deletes.

## High

### H1. Cache schema changed without a migration

`lib/src/database/tables.dart`, `lib/src/database/database.dart`

Commit `5d06c5b` renamed `sync_missing_tracks.last_inserted_at` to `source_added_at` and added `sync_playlist_tracks.added_at`, but `schemaVersion` is still 3 and `onUpgrade` has no step for it. Anyone upgrading from 1.5.1 keeps the old columns, and `sync` and `buy` then fail with "no such column". The local cache on the author's machine works only because it was patched by hand.

The existing upgrade code has a second bug: the v2 step runs only when `from == 1 && to == 2`. A database going from 1 straight to 3 never gets the sync tables.

Fix: bump to schema 4. Rewrite `onUpgrade` as cumulative steps (`if (from < 2)`, `if (from < 3)`, `if (from < 4)`). The v4 step checks `PRAGMA table_info` so it works on both untouched 1.5.1 databases and the hand-patched one. Add a test that opens a v3 database file built with the 1.5.1 schema and checks that the upgrade succeeds and keeps rows.

### H2. Every command needs the Spotify environment variables

`lib/src/cli/cli_dependencies.dart`, `lib/src/misc/env.dart`, `lib/src/spotify/api.dart`

`runWithCliDependencies` builds `Env.fromHostEnvironment()` before any command runs, and that throws when a variable is missing. So `in_phase --help`, `library sync engine`, `buy`, `config reveal`, `cues sync`, `cache clean` and `update` all fail with "Environment variables not found" even though they never talk to Spotify. Confirmed with `env -u SPOTIFY_CLIENT_ID dart run bin/in_phase.dart --help`.

Fix: read the environment in `spotifyLogin` only, and remove `Env` from zone injection.

### H3. Sync crashes on Spotify local files

`lib/src/cli/commands/sync_command.dart:204`

Sync keeps playlist entries where `track != null` and then calls `track.id!`. Local files in a Spotify playlist have a track object with a null id, so one local file aborts the whole sync. DJ playlists often contain local files.

Fix: one shared way to turn `PlaylistTrack` pages into tracks that have a Spotify id (see M6), used by every command.

### H4. Collect and crawl wipe playlists when a source fails

`lib/src/cli/commands/collect_command.dart:230`, `lib/src/cli/commands/crawl_command.dart:333-439`, `:777`

When fetching one source playlist fails, collect logs the error and carries on. In replace mode (the default) it then clears the target and writes it back without that source's tracks. Crawl does the same per source, and when every source fails it clears the output playlist on purpose ("Even if no tracks, clear the playlist"). A short network problem silently empties playlists that `sync` then copies into Rekordbox.

Fix: a failed source fails that collection or job. Nothing is written to Spotify for it, the error is reported, and the command exits non-zero at the end.

### H5. Playlist writes clear first and then add in batches

`collect_command.dart:367`, `crawl_command.dart:719`, `convert_command.dart:277`, `sort_command.dart:179`

All four commands call `playlists.clear()` and then `addTracks` in batches of 100. If any batch fails, the playlist is left empty or half full. The same 20 lines are copied four times, plus a fifth copy of "fetch existing ids, skip duplicates" for append mode.

Fix: one helper in `lib/src/spotify/` that writes a playlist. Replace mode uses `playlists.replace()` for the first 100 tracks (one atomic call) and appends the rest. Append mode skips tracks already in the playlist. All four commands use it.

## Medium

### M1. Request pool caches pages under keys that ignore page size

`lib/src/misc/request_pool.dart`, `lib/src/spotify/types.dart`

`SpotifyCacheIdentifier.playlistTracksPage(id, offset)` does not include the page size, but callers use 50 or 100. Successful requests are cached for an hour, so a playlist fetched with limit 50 and later with limit 100 in the same process mixes pages and returns duplicate tracks.

Other request pool problems:

- `request(ttl: Duration.zero)` cancels an earlier timer but leaves it in `_ttlTimers`, so `_cacheSuccess` sees the key and caches the result forever.
- `clear()` documents that active requests complete with an error, but only queued ones do. Running requests keep their state, finish later and decrement `_runningCount` below zero.
- The class doc promises exponential backoff. The delay is a fixed 5 seconds.

Fix: `fetchAllPages` always uses one page size (50, the limit every Spotify endpoint here accepts), so a page key always means the same request. The `limit` parameter goes away from `fetchAllPages` and its callers. Remove the timer entry when TTL is zero. Make `clear()` fail running requests too and reset all state. Correct the docs.

### M2. Config loading is copied five times and crashes on an empty file

`lib/src/entities/{sync,crawl,curate,collect,engine_sync}_config.dart`

Each config class has the same `fromFile` and `write` code. Curate, collect and crawl do `yamlDecode(content) as YamlMap`, so an empty or comment-only file crashes with a type error. Sync and engine sync have a proper `fromYamlString` with a readable error; engine sync also treats an empty file as defaults.

Fix: one shared YAML config loader in `lib/src/misc/` that reads the file, creates it with defaults when allowed, returns the default config for an empty document, and reports a non-map root clearly. The five classes keep only `fromJson`, `toJson` and their defaults.

### M3. iTunes lookup stores unrelated results

`lib/src/misc/itunes_store.dart:73`

`_selectBestTrackWebUrl` starts at `bestScore = -1`, so the first search result always wins even when neither artist nor title matches. `buy` saves that URL in the cache, so the wrong store page opens every time after that.

Fix: require at least a title match and an artist match (exact or containment) before accepting a result.

### M4. Fuzzy matching in sync is slow and duplicated

`sync_command.dart:594-701`, `lib/src/misc/fuzzy_search.dart`

For every unmatched track, sync starts four isolates and copies the full Rekordbox library (Drift row objects) into each, then normalizes every Rekordbox title again. `fuzzy_search.dart` has `findFuzzyTrackMatch`, which does the same thing and is never called. Both crash on a Rekordbox song with a null title (`song.title!`).

Fix: build the normalized Rekordbox search strings once per sync in `fuzzy_search.dart`, send only those strings to the isolates, and return the index of the best match. Delete the private copy in sync and the unused `findFuzzyTrackMatch`.

### M5. The same text normalizer exists five times

`fuzzy_search.dart:13`, `sync_command.dart:695`, `collect_command.dart:514`, `deduplicator.dart:69`, `itunes_store.dart:127`

All five lowercase, replace punctuation with spaces, collapse whitespace and trim. Collect also re-implements the deduplicator with a different rule (keep newest instead of keep first).

Fix: one `normalizeForMatch` in `fuzzy_search.dart` used everywhere. The deduplicator has one rule for both commands: keep the most recently added copy, at the position of the first copy. For crawl this only changes which duplicate's source and date are shown. Collect's private copy goes.

### M6. Spotify paging and client cleanup are repeated in every command

`*_command.dart`

- `(await api.client).close()` with an `invalid_use_of_visible_for_testing_member` ignore appears seven times, some with a TODO.
- Collect and crawl build their own teardown lists instead of using `withTeardown`, and catch `UsageException` in a catch-all so a usage error prints "Fatal error" and exits 70 instead of 64.
- Convert never closes the Spotify client.
- Each command has its own `track?.id != null` filtering (see H3).

Fix: one `closeSpotifyApi` helper in `lib/src/spotify/api.dart` (the only place with the lint ignore). All commands use `withTeardown`. Usage errors raised inside commands reach the runner unchanged. A `spotifyTracks` extension on `Iterable<PlaylistTrack>` returns the entries whose track has a Spotify id (local files have none).

### M7. Sort resets "added at" dates and drops local files

`lib/src/cli/commands/sort_command.dart:179`

Sort clears the playlist and re-adds the tracks it could read. Every track gets a new "added at" date, which `collect` (`track_order`) and `buy` (newest first) rely on. Local files and podcast episodes are filtered out before the rewrite, so they disappear from the playlist.

Fix: reorder in place with `playlists.reorder` (one move per out-of-place track, passing the snapshot id). That keeps dates and leaves non-track entries where they are.

### M8. Engine backups are deleted by `cache clean`

`lib/src/misc/constants.dart:36`, `lib/src/cli/commands/cache/cache_clean_command.dart`

`engineSyncBackupsDir` is inside `build/`, and `cache clean` deletes `build/` ("sync and crawl reports"). The only backups of the Engine library are removed without warning.

Fix: move backups to `~/.in_phase/backups/engine` and say so in `docs/ENGINE_SYNC.md`.

### M9. Crawl job code is copied per source type

`crawl_command.dart:330-460`, `:502-560`

The playlist, artist, label and YouTube blocks are four copies of the same "start collecting, report progress, swallow errors" code. The template engine is called three times with the same eleven arguments.

Fix: one helper that runs a collection future against the progress display, and one template context built once per job.

### M10. Two YouTube to Spotify matchers

`lib/src/crawl/track_collector.dart:1368-1480`, `lib/src/convert/youtube_spotify_matcher.dart`

Crawl's YouTube channel input uses an older title parser and search strategy. `convert` has a newer, tested matcher (topic channels, featured artists, scoring). The same video can match differently depending on the command.

Fix: crawl uses the convert matcher; delete the old helpers in `track_collector.dart`.

## Low

### L1. Typed Spotify ids return the wrong type

`lib/src/spotify/types.dart:39-70`. `SpotifyArtistId.tryParse`, `SpotifyAlbumId.tryParse` and `SpotifyTrackId.tryParse` return `SpotifyPlaylistId`. None are called. Fix: delete them.

### L2. Dead code and dead config

- `lib/src/cache/legacy_cache.dart` is not imported anywhere.
- `TrackAlbumMappings` and its DAO are never written or read (the table is empty in a real cache). `CacheMetadata` is created and initialized on every start but never read; `updateLastUpdated` is never called.
- Unused DAO methods: `getAlbumsByReleaseDate`, `upsertAlbum`, `isArtistStale`, `setMapping`. Unused `CacheAdapter.updateMetadata`, `StringExtensions.hasContent`, `Zonable.call`.
- `NullableExtensions.or` and `orElse` return `T?` although the result is never null.
- `pubspec.yaml` has a `pubspec_extract` block for a generator the project does not use.

Fix: delete them. The v4 migration drops the two dead tables.

### L3. Camelot key detection in playlist names is too loose

`sync_command.dart:47`, `:612`. The regex is not anchored, so a word like `4AM` counts as key 4A, and its comment describes the pattern wrongly. Fix: anchor it to the whole word.

### L4. `buy` reopens a link only once

`buy_command.dart:63`. After `o`, the next key press always moves on, even another `o`. Fix: loop until the action is not "reopen".

### L5. `login --force` still refreshes the cached token first

`api.dart:57`. `useCache: false` runs the cached login (a network call and a write) and then ignores the result. Fix: skip the cached path entirely.

### L6. Errors lose their stack trace

`runner.dart:73`. The runner prints only `e`, even with `--verbose`. Fix: print the stack trace in verbose mode.

### L7. `update` downgrades a newer local build

`update_command.dart:33` compares versions with `==`. Fix: use `PubUpdater.isUpToDate`.

### L8. `--memory-cues-to-hot-cues` cannot turn the config value off

`library_sync_engine_command.dart:29`. The flag is not negatable, unlike `--prune`. The comment "Never write while either application is running" only checks Engine. Fix: make the flag negatable and honour `wasParsed`; correct the comment.

### L9. Custom tracks drop duplicate songs

`sync_command.dart:430`. When a playlist has custom tracks, the queue is turned into a map keyed by Rekordbox id, which silently removes a song that appears twice. Playlists without custom tracks keep duplicates. Fix: pass the queue list as is.

### L10. Freshness checks are written in a roundabout way

`daos.dart:192-210`, `:282-300`. "cached date is after yesterday" means "cached today". Fix: one `isSameDay` helper.

### L11. Credentials entry is bound to the first zone

`api.dart:35`. `_credentialsEntry` is a lazy top-level final that reads `Doos` from whichever zone touches it first. Fix: look it up per call.

### L12. Version is kept in two places without a check

`pubspec.yaml` and `Constants.version` are bumped by `prepare_release.sh`, but nothing fails if they drift. Fix: a test that compares them.

### L13. `ensureDefaultConfigs` deletes a file named `~/.in_phase`

`config_initializer.dart:14`. If a file (not a folder) has that name, it is deleted without asking. `File.exists` is already false for directories, so the extra type check does nothing. Fix: fail with a clear message instead of deleting.

### L14. Curate resolves playlists with two copies of the same code

`curate_command.dart:336-417`. `_resolveTargets` and `_resolveSourcePlaylist` differ only in messages. `_digitFromLogicalKey` is a nine-branch if chain. Fix: one resolve function; a lookup list for digits.

## Not changing

- Sync deletes and recreates a Rekordbox playlist by name wherever it is in the tree, not only in its configured folder. Matching by folder as well would leave old copies behind when a folder rule changes. That is a product decision, so it stays as is.
- Engine backups have no retention limit. Worth adding once there is a decision on how many to keep.
- `log.warning` and `log.error` print to stdout. Moving them to stderr changes what people see when piping output; left alone.

## Fix plan

Order of work. Each step ends with format, analyze and tests passing, and gets its own commit.

1. H1 and L2 tables: schema 4 with cumulative migrations, drop `track_album_mappings` and `cache_metadata`, migration test. Deletes: `TrackAlbumMappings`, `TrackAlbumMappingsDao`, `CacheMetadata`, `MetadataDao`, the metadata init in `createDatabase`.
2. H2 and L5, L11: environment read in `spotifyLogin`; credentials entry looked up per call. Deletes: `Env` zone injection.
3. M6, H3, H4, H5, L6: Spotify helpers (`closeSpotifyApi`, `spotifyTracks`, playlist writer), all commands on `withTeardown`, failed sources stop the write. Deletes: the hand-rolled teardown lists in collect and crawl, four copies of clear-and-add, the append-mode duplicate filter copies, seven lint ignores.
4. M1: request pool fixes and one page size. Deletes: the `limit` parameter of `fetchAllPages` and every `limit:` argument passed to it.
5. M2 and L13: shared YAML config loader. Deletes: five `fromFile`/`write` bodies.
6. M4 and M5: one normalizer, one fuzzy matcher with a prebuilt index, deduplicator with keep-newest. Deletes: `findFuzzyTrackMatch`, sync's `_findFuzzyMatch` and `_normalizeQuery`, collect's `_deduplicateKeepingLatest` and `_normalizeForMatch`, the deduplicator's and iTunes' private normalizers.
7. M3, L4: iTunes match threshold, buy reopen loop.
8. M7: sort reorders in place.
9. M8, L8: backups out of `build/`, negatable cue flag.
10. M9, M10: crawl source helper and template context; crawl uses the convert matcher.
11. Remaining low items: L1, L2 code, L3, L7, L9, L10, L12, L14.
