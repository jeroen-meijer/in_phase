## Upcoming

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
