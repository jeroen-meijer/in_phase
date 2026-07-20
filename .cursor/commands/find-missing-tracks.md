# /find-missing-tracks

Find Spotify tracks marked missing during sync that are actually in Rekordbox, propose Spotify→Rekordbox mappings, get user approval, then write them to the local sync cache.

Scripts live in `tool/ai/find_missing_tracks/`. Review artifacts go to `~/.in_phase/build/find_missing_tracks/`.

Do **not** run `in_phase sync` unless the user explicitly asks.

---

## Agent execution (read first)

### Sandbox: most Dart commands need full permissions

Cursor's terminal sandbox **blocks** the workflow scripts. Always run with **`required_permissions: ["all"]`**:

- `dart run tool/ai/find_missing_tracks/list_playlists.dart`
- `dart run tool/ai/find_missing_tracks/prepare.dart` (slow — loads full Rekordbox library)
- `dart run tool/ai/find_missing_tracks/apply.dart`
- `dart run tool/ai/find_missing_tracks/cleanup.dart`
- `./run.sh search ...` (optional spot-check only; use `run.sh`, not `dart run bin/in_phase.dart`)

In sandbox they fail on `~/.dart-tool/` telemetry, cannot write `~/.in_phase/build/`, and cannot open the Rekordbox database reliably.

**Read-only fallback** (sandbox OK): `sqlite3 ~/.in_phase/cache.db "..."` for quick counts — not a substitute for `prepare`.

### No Dart REPL or inline execution

Dart is **compiled**. These do **not** work — do not try:

- `dart -e '...'` / `dart --eval`
- `echo 'void main() {}' | dart`
- piping heredocs into `dart` as if it were Python/node

Use **`dart run path/to/script.dart`** for `tool/ai/...` workflow scripts. For **in_phase CLI** (e.g. `search`), use **`./run.sh`**, not `dart run bin/in_phase.dart`. For one-off logic, use the **Read** tool on generated JSON/Markdown, or extend the scripts below.

### Use the scripts, not ad-hoc tooling

- **`prepare.dart`** already runs Rekordbox search for every missing track — do not loop `in_phase search` per track.
- After prepare, read `candidates.json` and `review_brief.md` with the **Read** tool (paths under `~/.in_phase/build/find_missing_tracks/`).
- Do not write throwaway `tool/debug_*.dart` or Python parsers unless truly one-off.

**If you hit a gap that will recur** (e.g. a new filter, report format, validation step), add it to `tool/ai/find_missing_tracks/` and update this command — don't leave one-off scripts for the next run.

### Paths (any user)

| What | Where |
|---|---|
| Sync cache DB | `~/.in_phase/cache.db` |
| Review output | `~/.in_phase/build/find_missing_tracks/` |
| Scripts | `tool/ai/find_missing_tracks/` (from repo root) |

---

## Step 0: Ask which playlists to scan (required)

Do **not** assume a playlist naming scheme. Ask the user what to include — their answer may be informal, e.g.:

- "all missing tracks"
- "only playlists whose name contains `DJ`"
- "names ending in `_SET`"
- "starts with `COL_` or contains `Weekly`"
- an exact playlist name

Run `list_playlists.dart` first (no filter) to show what's in cache:

```bash
dart run tool/ai/find_missing_tracks/list_playlists.dart
```

Translate the user's intent into a **Dart regex** on synced playlist names (`--playlist-regex`, repeat for OR). Preview with the same flag before `prepare`.

| User says | Regex |
|---|---|
| contains `DJ` | `.*DJ.*` or `(?i).*dj.*` |
| ends with `_SET` | `.*_SET$` |
| starts with `COL_` | `^COL_` |
| exact name `My Mix` | `^My Mix$` |
| contains DJ **or** ends with `_SET` | `(?i).*dj.*\|.*_SET$` |
| starts with `COL_` or `SET_` | `^(COL_|SET_)` |

Preview a scope:

```bash
dart run tool/ai/find_missing_tracks/list_playlists.dart --playlist-regex '(?i).*dj.*|.*_SET$'
```

Only run `prepare` after the user confirms the regex.

---

## Step 1: Prepare review data

From the repo root.

**All missing tracks** (only when the user asked for no filter):

```bash
dart run tool/ai/find_missing_tracks/prepare.dart
```

**Filtered scope**:

```bash
dart run tool/ai/find_missing_tracks/prepare.dart --playlist-regex '(?i).*dj.*|.*_SET$'
```

This writes:

- `~/.in_phase/build/find_missing_tracks/candidates.json` — machine-readable search results
- `~/.in_phase/build/find_missing_tracks/review_brief.md` — human/agent review summary

Read both. Start with near misses (sync score 70–79), then review the rest.

---

## Step 2: LLM matching pass (you)

For **every** track in `candidates.json`, decide whether a Rekordbox hit is the **same track**.

### Matching rules

- **Always judge artist + title together.** Never match on title alone (`Vibe`, `Closer`, etc.).
- Primary Spotify artist must appear in the Rekordbox artist (allow spelling variants like `MAREA` / `Mara Sophia`).

### Remixes and versions (critical)

The **same remix/version** must match on both sides. When in doubt, reject.

| Spotify | Rekordbox | Verdict |
|---|---|---|
| `Artist - Song` | `Artist - Song (Someguy Remix)` | **Reject** — original ≠ remix |
| `Artist - Song (Calibre Remix)` | `Artist - Song (Calibre Remix)` | OK — same remix |
| `Artist - Song - Calibre Remix` | `Artist - Song [Calibre Remix]` | OK — naming variant, same remix |
| `Artist - Song (YUSSI VIP)` | `Artist - Song (feat. X)` | **Reject** — different versions |
| `Artist - Song` | `Artist - Song (Extended Mix)` | OK only if same release (not a different mix) |

Rules:
- If Spotify has **no** remix/VIP/mix suffix, Rekordbox must **not** be a named remix/VIP unless you are sure it is the same file with messy tags.
- If Spotify **is** a specific remix, Rekordbox must name the **same** remixer/version (allow punctuation/`feat.` differences only).
- **VIP**, **Bootleg**, **Edit**, **Dub**, **Instrumental**, and **Radio Edit** are different versions — do not cross-match.
- Near-miss sync scores often mean "similar title, wrong version" — check remix lines first.

OK formatting-only differences (same track): `(feat. X)` vs `feat. X`, mastering tags, `(Original Mix)` when both refer to the same non-remix release.

**Reject** when:
- Different remix/version (see above)
- Acapella/stem files (`_(Vocals)`, `Unknown Artist` stems)
- Same artist but clearly different song title
- Wrong artist even if title is similar

Sync fuzzy threshold is **80**. Propose mappings only when you are confident the Rekordbox track is the same release the user owns.

Write proposals to:

`~/.in_phase/build/find_missing_tracks/proposed_mappings.json`

```json
{
  "proposed_at": "ISO-8601",
  "mappings": {
    "spotify_track_id": "rekordbox_track_id"
  },
  "entries": [
    {
      "spotify_track_id": "...",
      "rekordbox_track_id": "...",
      "spotify": "Artist - Title",
      "rekordbox": "Artist - Title",
      "sync_score": 76,
      "reason": "Why this is the same track"
    }
  ]
}
```

If no mappings found, still create the file with empty `mappings` and `entries`.

---

## Step 3: Present for user approval (mandatory)

Show a compact table of every proposed mapping:

| Spotify | Rekordbox | Sync score | Reason |
|---|---|---:|---|

Ask the user to approve, edit, or reject individual rows.

**Do not apply until the user explicitly approves.**

After approval, write the final list to:

`~/.in_phase/build/find_missing_tracks/approved_mappings.json`

Same schema as proposed; set `"approved_at"` and keep only approved entries.

---

## Step 4: Apply approved mappings

Dry run first:

```bash
dart run tool/ai/find_missing_tracks/apply.dart --dry-run
```

Then apply and clean up temp files:

```bash
dart run tool/ai/find_missing_tracks/apply.dart --cleanup
```

This upserts `sync_track_mappings` in `~/.in_phase/cache.db` and removes matched rows from `sync_missing_tracks`.

To remove review artifacts without applying:

```bash
dart run tool/ai/find_missing_tracks/cleanup.dart
```

---

## Notes

- Requires a prior sync run (missing tracks in cache.db).
- Rekordbox must be readable (database accessible).
- Never run sync/crawl or clear sync cache without user permission.
- `prepare.dart` can take 15–30s+ depending on library size; use a long `block_until_ms` (e.g. 120000+) when running it.
- `apply.dart --dry-run` needs `approved_mappings.json` to exist first.
