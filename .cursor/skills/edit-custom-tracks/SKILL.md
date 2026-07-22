---
name: edit-custom-tracks
description: >-
  Add or adjust in_phase sync custom_tracks entries (insert after/before,
  replace, absolute index). Use whenever the user asks to put a Rekordbox track
  into a Spotify playlist's custom_tracks, place a track after/before another
  song, replace a track in sync_config, or mentions custom_tracks / sync_config
  track overrides for a set/playlist.
---

# Edit custom_tracks

Resolve IDs with `tool/ai/edit_custom_tracks/resolve.dart`, then **you**
surgically edit `~/.in_phase/sync_config.yaml`. Never rewrite the whole file
with `yamlEncode` / `SyncConfig.write` — that drops comments and formatting.

**Read `tool/ai/edit_custom_tracks/learnings.md` before resolving** (known
pitfalls). After friction, update it (see Self-learning below).

## When to use

- "put X after Y in the festival set"
- "replace Circles with Oppidan bootleg in SET_…"
- "add this rekordbox id at the start of playlist …"
- Any request to change `custom_tracks` for a synced Spotify playlist

## Workflow

1. Skim `learnings.md` for relevant bullets.
2. Parse intent → `--playlist`, `--add`, and one of `--after` / `--before` /
   `--replace` / `--index` / `--position`.
3. Resolve (script does **not** write the config):

```bash
dart run tool/ai/edit_custom_tracks/resolve.dart \
  --playlist '<name or spotify playlist id>' \
  --add '<rb id | spotify url/id | track name>' \
  --after '<rb id | spotify track url/id | name>'
```

Stdout is JSON: `playlist`, `track`, `target`, `yaml_entry`, `config_path`,
`instruction`.

4. If resolution failed:
   - Run `--search` on the failing name (do **not** invent one-off tmp scripts):

```bash
dart run tool/ai/edit_custom_tracks/resolve.dart --search 'So Good'
```

   - Retry `--add` / `--after` with an accepted `rekordbox_id` from the hits.
   - If still stuck, tell the user — do not invent a `rekordbox_id`.
5. If fuzzy matches look wrong, confirm with the user before editing.
6. **Apply yourself:** open `config_path` and surgically insert `yaml_entry`
   under `custom_tracks:` → `  <playlist.id>:` (add the playlist key with a
   `# <playlist.name>` comment if missing). Match existing comment style.
   Check for an obvious duplicate entry first. If workspace StrReplace cannot
   edit `~/.in_phase/…`, patch that absolute path via a short Python/shell
   snippet.
7. Do **not** run `sync` unless the user asks.
8. If you hit new friction, **self-learn** (below) before ending the turn.

## Self-learning (required after friction)

When resolve fails, a fuzzy hit is wrong, YAML edit is awkward, or you invent a
workaround:

1. Prefer fixing `lib.dart` / `resolve.dart` if the issue is general (scoring,
   flags, error messages).
2. Append a dated bullet to `tool/ai/edit_custom_tracks/learnings.md`
   (concrete: symptom → fix/command).
3. Update this `SKILL.md` only if the workflow itself changed.
4. Do not leave `tool/tmp_*.dart` (or similar) behind — use `--search` or
   fold helpers into `lib.dart`.

## CLI flags

| Flag | Meaning |
| --- | --- |
| `--playlist` / `-p` | Playlist name (fuzzy on sync cache), or Spotify playlist id/URI/URL |
| `--add` / `-a` | Payload: Rekordbox id, Spotify id/URI/URL (`sync_track_mappings`), or name. **Must exist in Rekordbox** |
| `--artist` | Optional artist hint for `--add` / `--search` (or write `Title by Artist`) |
| `--after` | Insert 1 slot after anchor |
| `--before` | Insert 1 slot before anchor (`index: -1`) |
| `--replace` | Replace anchor with `--add` (`type: replace`) |
| `--type insert\|replace` | Default `insert`; usually implied by anchor flags |
| `--index` / `--position` | Absolute placement when there is no anchor |
| `--search` | List top Rekordbox matches for a query (JSON); no config write |
| `--search-limit` | Max `--search` hits (default 15) |
| `--human` | Human-readable snippet instead of JSON |

## Resolution rules

- Playlist: sync `cache.db` names/ids; newest year among substring hits (skips
  `(OLD)`).
- `--add`: RB id → library check; Spotify → `sync_track_mappings`, else fuzzy
  name/artist search in Rekordbox (title/artists from sync cache or Spotify
  API — often misses if never mapped); name → fuzzy (`scoreNameMatch`:
  title-only, partial, prefix/word boosts). Error if not in Rekordbox.
- Anchors: same scoring against playlist-cache titles (short names like
  `Twerp` must work).
- Fuzzy score &lt; 80 → fail with top candidates + `--search` hint.

## Notes

- Config: `~/.in_phase/sync_config.yaml` (not in the git repo).
- `custom_tracks.target` is still Rekordbox-only in product code; this tool
  bridges Spotify anchors → RB ids via cache + fuzzy match.
