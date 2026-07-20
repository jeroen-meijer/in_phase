# /find-incorrect-duplicate-tracks

Find **suspicious duplicate mappings** where multiple Spotify track IDs map to
the same Rekordbox track ID in the sync cache (`sync_track_mappings`), produce a
review brief, then apply user-approved fixes.

Scripts live in `tool/ai/find_incorrect_duplicate_tracks/`. Review artifacts go
to `~/.in_phase/build/find_incorrect_duplicate_tracks/`.

Do **not** run `in_phase sync` unless the user explicitly asks.

---

## Agent execution (read first)

### Sandbox: most Dart commands need full permissions

Cursor's terminal sandbox **blocks** this workflow. Always run with
**`required_permissions: ["all"]`**:

- `dart run tool/ai/find_incorrect_duplicate_tracks/prepare.dart`
- `dart run tool/ai/find_incorrect_duplicate_tracks/apply.dart`
- `dart run tool/ai/find_incorrect_duplicate_tracks/cleanup.dart`

**Read-only fallback** (sandbox OK): `sqlite3 ~/.in_phase/cache.db "..."` for
quick counts only.

### No Dart REPL or inline execution

Dart is **compiled**. These do **not** work:

- `dart -e '...'` / `dart --eval`
- `echo 'void main() {}' | dart`

Use **`dart run path/to/script.dart`** for `tool/ai/...` workflow scripts. For **in_phase CLI** (e.g. `search`), use **`./run.sh`**, not `dart run bin/in_phase.dart`.

### Paths (any user)

| What | Where |
|---|---|
| Sync cache DB | `~/.in_phase/cache.db` |
| Review output | `~/.in_phase/build/find_incorrect_duplicate_tracks/` |
| Scripts | `tool/ai/find_incorrect_duplicate_tracks/` (from repo root) |

---

## Step 1: Prepare review data

From the repo root:

```bash
dart run tool/ai/find_incorrect_duplicate_tracks/prepare.dart
```

Optional knobs:

- `--limit N`: only inspect the first N duplicate Rekordbox IDs (0 = all)
- `--include-clean`: also include groups that look “probably OK”

This writes:

- `~/.in_phase/build/find_incorrect_duplicate_tracks/candidates.json`
- `~/.in_phase/build/find_incorrect_duplicate_tracks/review_brief.md`

---

## Step 2: LLM review (you)

Goal: for each Rekordbox ID group, decide what to do for each Spotify ID:

- **Keep** mapping as-is
- **Remap** Spotify ID to the correct Rekordbox ID
- **Delete** mapping (force re-match next time)

### Matching rules (version safety)

- Always judge **artist + title together**
- Do **not** cross-match versions:
  - original ≠ remix/VIP/edit/bootleg/instrumental/radio edit
- If Spotify metadata is missing in cache (title/artist unknown), you cannot
  confidently keep it. Prefer **delete** unless you resolve it another way.

When you’re ready, write the approved changes to:

`~/.in_phase/build/find_incorrect_duplicate_tracks/approved_fixes.json`

Schema:

```json
{
  "approved_at": "ISO-8601",
  "remap": { "spotify_track_id": "rekordbox_track_id" },
  "delete": ["spotify_track_id"],
  "entries": [
    { "spotify_track_id": "...", "rekordbox_track_id": "...", "action": "remap", "reason": "..." },
    { "spotify_track_id": "...", "action": "delete", "reason": "..." }
  ]
}
```

---

## Step 3: Apply approved fixes

Dry run first:

```bash
dart run tool/ai/find_incorrect_duplicate_tracks/apply.dart --dry-run
```

Then apply and optionally clean up:

```bash
dart run tool/ai/find_incorrect_duplicate_tracks/apply.dart --cleanup
```

To remove artifacts without applying:

```bash
dart run tool/ai/find_incorrect_duplicate_tracks/cleanup.dart
```

---

## Notes

- Requires a prior sync (so `sync_track_mappings` exists).
- Rekordbox DB must be readable; this tool connects with
  `allowConnectionWhenRunning: true`.

