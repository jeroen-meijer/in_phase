# Engine Sync

`in_phase library sync engine` performs a one-way sync of your Rekordbox
library into the Engine DJ desktop library: tracks, beat grids, hot cues,
memory cues, loops, and playlists. Rekordbox is only ever read, never
written.

```bash
in_phase library sync engine            # sync Rekordbox → Engine DJ
in_phase library sync engine --dry-run  # report only, no writes
in_phase library doctor                 # check both libraries are ready
```

## Requirements

- Rekordbox 6/7 with a local `master.db` (same requirements as other
  `in_phase` Rekordbox commands, including SQLCipher).
- Engine DJ 4.x or 5.x desktop with an existing library (database schema
  3.0.x). Launch Engine DJ once so it creates `~/Music/Engine Library`.
- Both Rekordbox and Engine DJ must be closed while syncing.

## Configuration

Config lives at `~/.in_phase/engine_sync_config.yaml`:

```yaml
# Engine Library directory (default: ~/Music/Engine Library)
# engine_library_path: "~/Music/Engine Library"

# Rekordbox analysis files directory containing PIONEER/
# (default: <rekordbox database dir>/share)
# anlz_root_path: "~/Library/Pioneer/rekordbox/share"

# Remove Engine tracks/playlists that are absent from Rekordbox, making
# Engine an exact mirror of Rekordbox. Disable to only add/update.
prune: true

# Spill memory cues into empty hot cue slots (Engine has no memory cues).
memory_cues_to_hot_cues: false

# Sync album artwork from Rekordbox ImagePath into Engine (default: true).
sync_art: true
```

Flags override the config: `--dry-run`, `--no-prune`,
`--memory-cues-to-hot-cues`, and `--config`/`-c` for an alternative config
file path.

## What gets synced

| Rekordbox | Engine DJ |
|---|---|
| Track metadata (title, artist, album, genre, comment, label, composer, remixer, key, rating, year, BPM) | `Track` columns |
| Beat grid (ANLZ `.DAT`, `PQTZ` tag) | `beatData` blob, grid locked so Engine's analysis never overwrites it |
| Hot cues A-H | Hot cue slots 1-8 (Engine's standard slot colors) |
| First memory cue | Main cue position |
| Memory cues (optional) | Empty hot cue slots, with `memory_cues_to_hot_cues` |
| Memory/hot cue loops | Loop slots 1-8 (max 8, in track-position order) |
| Album artwork (`ImagePath` JPEGs under `PIONEER/Artwork/`) | `AlbumArt` blob + `albumArtId`; on Engine DJ 5.0 also `Artwork/{sha1}.jpg` |
| Playlists and folders | `Playlist` tree with identical structure and order |

Beat grid and cue positions are phase-aligned to Rekordbox downbeats. For
m4a/AAC/MP3 files, a standard encoder priming offset (~48 ms at 44.1 kHz
for AAC) is subtracted so markers line up with Engine's waveform timeline.

Tracks are matched between the two libraries by Rekordbox content ID
(stored in Engine's `pdbImportKey` column), falling back to the audio file
path. The sync is idempotent: unchanged tracks are detected and skipped.

## What does NOT get synced

- Waveforms and loudness analysis. Engine DJ analyzes tracks itself the
  first time they are loaded; only the beat grid is locked. Re-syncing
  unchanged tracks does not reset analysis — only new or changed tracks
  are re-analyzed.
- Smart playlists, My Tags, histories, and hot cue banks.
- Streaming tracks (Engine-side streaming entries are never touched).
- Anything back into Rekordbox; the sync is strictly one-way.

## Safety

- The command refuses to run while Rekordbox or Engine DJ is running.
- Before every write run, `m.db` (plus WAL/SHM sidecars) is backed up to
  `~/.in_phase/build/engine_sync_backups/<timestamp>/`.
- `--dry-run` prints the full change report without opening the database
  for writing.
- The Engine database schema is validated (`Information.schemaVersion`
  must be 3.0.x) and never modified; only rows are inserted, updated, or
  deleted.

## Pruning

With `prune: true` (default), the Engine library becomes an exact mirror:

- Engine tracks whose Rekordbox source disappeared are deleted (streaming
  tracks excluded).
- The entire playlist tree is rebuilt each run so structure and ordering
  match Rekordbox exactly.

With `--no-prune` (or `prune: false`), tracks are only added or updated,
existing playlists are matched by name and their contents replaced, and
unknown Engine playlists are left untouched (new playlists append at the
end without reordering).
