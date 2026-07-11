# Collect Configuration

The `collect` command uses a `collect_config.yaml` file to configure playlist aggregation: combining tracks from multiple Spotify playlists into a single target playlist. The config file is automatically created at `~/.in_phase/collect_config.yaml` on first run.

**Tip:** Use `in_phase config reveal` to quickly open the config directory in your file manager, making it easy to find and edit configuration files.

## Overview

The collect command aggregates tracks from multiple source playlists into one target playlist. Unlike `crawl` (which creates new playlists from filtered time-ranged sources), collect:

- Takes **all tracks** from each source playlist (no date filtering)
- **Replaces** the target playlist contents entirely on each run (idempotent updates)
- Requires the **target playlist to already exist** (you must create it manually first)
- Supports **playlist ID, URI, URL, fuzzy name (≥80% match), or glob patterns** for source/target resolution

This is useful for maintaining aggregated playlists that combine tracks from multiple sources, such as collecting all your "Drum & Bass" playlists into a single "My DnB Collection" playlist.

## Configuration Structure

Collect YAML uses **snake_case** (underscores) for option keys and string enum values, for example `deduplicate: on_match`, `track_order: newest_first`. This matches the other InPhase config files.

The config file has two main sections:

1. `**_notes`** - Optional section for defining YAML anchors (reusable IDs). Is **not** used by the tool but is useful for referencing playlist IDs in the collections section.
2. `**collections`** - List of collection configurations. Each collection aggregates multiple source playlists into one target.

### Example Configuration

```yaml
# Optional YAML anchors for reusable playlist IDs
_notes:
  playlists:
    liquicity: &playlist_liquicity '5GH6XFP11JTr9wzwsNESwY'
    hospital_records: &playlist_hospital '37i9dQZF1DXcBWIGoYBM5M'

collections:
  - name: drum_and_bass
    target: "37i9dQZF1DXcBWIGoYBM5M"   # Playlist ID, URI, or share URL
    # OR: target: "My DnB Collection"  # Exact or fuzzy playlist name
    description: "Last updated: {real_datetime}"  # Optional description template
    sources:
      # Mix of: IDs, URIs, URLs, exact names, glob patterns
      - *playlist_liquicity            # YAML anchor reference
      - "37i9dQZF1DXcBWIGoYBM5M"      # Direct playlist ID
      - "DnB Releases*"                # Glob pattern (matches playlist names)
      - "Liquid Drum & Bass"           # Exact playlist name
    options:
      deduplicate: on_match            # on_id | on_match (default: on_id)
      replace: true                    # true = replace, false = append (default: true)
      track_order: oldest_first        # oldest_first | newest_first (default: oldest_first)
```

## Collection Configuration

Each collection in the `collections` array defines a single aggregation task.

### Required Fields

- `**name**` - Unique identifier for the collection (used in logs and `--collection` filter)
- `**target**` - Target playlist identifier. Must exist and be writable. Can be:
  - Playlist ID (e.g., `37i9dQZF1DXcBWIGoYBM5M`)
  - URI (e.g., `spotify:playlist:37i9dQZF1DXcBWIGoYBM5M`)
  - Share URL (e.g., `https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M`)
  - Exact or fuzzy playlist name from your playlists (≥80% token match; must be unique)
- `**sources**` - List of source playlist identifiers. Each can be:
  - Playlist ID, URI, or share URL (works for any accessible playlist)
  - Glob pattern (e.g., `"DnB Releases*"` matches playlist names)
  - Exact or fuzzy playlist name (duplicate exact names fail ambiguous)
- **Note:** `likes` is not a valid collect target (Liked Songs is not a playlist). Use `in_phase convert --add likes` to save tracks to Liked Songs.

### Optional Fields

- `**description**` - Template string for playlist description (supports template variables). Updated every time the command runs. See [Template Variables](#template-variables) below.
- `**options**` - Processing options
  - `**deduplicate**` - Deduplication mode: `on_id` or `on_match` (default: `on_id`)
    - `on_id` - Remove tracks with duplicate Spotify track IDs
    - `on_match` - Remove tracks with matching artist names and track titles (fuzzy matching)
  - `**replace**` - Whether to replace all tracks in the target playlist or append to existing tracks (default: `true`)
    - `true` (default) - Clear the playlist and replace with new tracks
    - `false` - Append new tracks to the end of the existing playlist
  - `**track_order**` - Order tracks in the target playlist by each track's `added_at` time from the source playlist(s) (default: `oldest_first`)
    - `oldest_first` - Earliest `added_at` first in the target playlist
    - `newest_first` - Latest `added_at` first in the target playlist

## Source Resolution

The collect command resolves source playlists in the following order:

1. **ID/URI/URL**: If the source can be parsed as a playlist ID (via `SpotifyPlaylistId.tryExtract()`), it fetches the playlist directly by ID. This works for playlists you own, follow, or have collaborative access to.
2. **Glob Pattern**: If the source contains glob characters (`*`, `?`, `[`, `]`), it's treated as a glob pattern. The command fetches all your playlists and filters them by name using the glob pattern.
  - Example: `"DnB Releases*"` matches "DnB Releases 2024", "DnB Releases Weekly", etc.
  - Example: `"*House*"` matches any playlist with "House" in the name
3. **Exact Name**: Otherwise, the source is treated as an exact playlist name match from your playlists.

**Deduplication**: After resolution, the command deduplicates resolved playlists by ID, so if the same playlist is specified multiple ways (e.g., by ID and by name), it's only processed once.

## Target Playlist

The target playlist **must already exist** before running the collect command. You can create it manually in Spotify, or use another tool. The collect command will:

- Replace all tracks in the target playlist with the aggregated tracks
- Update the playlist description if a `description` template is configured
- Preserve the playlist name and other metadata
- Only work if you have edit access to the playlist (you own it or have collaborative edit access)

**Important**: By default, running collect will **replace** all existing tracks in the target playlist. Any tracks you manually added will be removed on the next collect run. To preserve existing tracks, set `replace: false` in the collection options.

### Target Playlist Resolution

The command resolves the target playlist as follows:

1. **ID/URI/URL**: If the target can be parsed as a playlist ID (via `SpotifyPlaylistId.tryExtract()`), it fetches the playlist directly by ID. If the playlist is not found or you don't have access, the command fails with a clear error message.
2. **Exact Name**: Otherwise, the target is treated as an exact playlist name match from your playlists:
  - **0 matches**: Command fails with an error suggesting to check the name or use a playlist ID
  - **1 match**: Uses that playlist
  - **Multiple matches**: Command fails with an error listing all matches and suggesting to use a playlist ID instead

**Error Handling**: If the target playlist cannot be resolved, the command stops processing that collection and logs clear error messages with suggestions on how to fix the issue.

## Using YAML Anchors

YAML anchors allow you to define reusable playlist IDs in the `_notes` section and reference them in collections. This makes it easier to manage large configurations.

```yaml
_notes:
  playlists:
    liquicity: &playlist_liquicity '5GH6XFP11JTr9wzwsNESwY'
    hospital_records: &playlist_hospital '37i9dQZF1DXcBWIGoYBM5M'

collections:
  - name: drum_and_bass
    target: "My DnB Collection"
    sources:
      - *playlist_liquicity      # Reference the anchor
      - *playlist_hospital
      - "DnB Releases*"          # Mix with glob patterns
```

## Template Variables

The `description` field supports template variables enclosed in curly braces `{}`. Available variables:

### Date and Time Variables

- `{real_date}` - Current date (YYYY-MM-DD format, e.g., `2024-01-15`)
- `{real_datetime}` - Current date and time (YYYY-MM-DD HH:MM format, e.g., `2024-01-15 14:30`)
- `{real_datetime_full}` - Current date and time with seconds (YYYY-MM-DD HH:MM:SS format, e.g., `2024-01-15 14:30:45`)
- `{real_time}` - Current time (HH:MM format, e.g., `14:30`)
- `{real_time_with_seconds}` - Current time with seconds (HH:MM:SS format, e.g., `14:30:45`)

### Content Statistics

- `{track_count}` - Number of tracks in the aggregated playlist
- `{source_count}` - Number of source playlists used

### Example Descriptions

```yaml
description: "Last updated: {real_datetime}"
# Renders as: "Last updated: 2024-01-15 14:30"

description: "Collected {track_count} tracks from {source_count} playlists on {real_date}"
# Renders as: "Collected 150 tracks from 5 playlists on 2024-01-15"

description: "Updated {real_datetime_full}"
# Renders as: "Updated 2024-01-15 14:30:45"
```

## Deduplication

The `deduplicate` option controls how duplicate tracks are handled:

- `**on_id**` (default) - Remove tracks with duplicate Spotify track IDs. Keeps the first occurrence based on source order.
- `**on_match**` - Remove tracks with matching artist names and track titles using fuzzy matching. Useful when the same track appears in multiple playlists with slightly different metadata.
- Not specified - No deduplication (all tracks from all sources are included)

## Replace vs Append Mode

The `replace` option controls how tracks are added to the target playlist:

- `**replace: true**` (default) - Clears the target playlist and replaces all tracks with the aggregated tracks. This ensures the playlist only contains tracks from the configured sources.
- `**replace: false**` - Appends the aggregated tracks to the end of the existing playlist. Existing tracks remain, and new tracks are added after them. **Duplicate tracks are automatically skipped** - if a track is already in the playlist (by Spotify track ID), it won't be added again.

**Important**: When using `replace: true` (the default), any tracks you manually added to the target playlist will be removed on the next collect run. If you want to preserve manually added tracks, set `replace: false`.

**Duplicate Detection**: When appending (`replace: false`), the command checks existing tracks in the target playlist and only adds tracks that aren't already present. This prevents duplicate tracks from being added to the playlist.

## Track Ordering

After fetching all source tracks, the command **deduplicates** (if configured), then sorts the result by each track's `**added_at`** timestamp (when it was added to its source playlist).

The `**track_order`** option controls that sort:

- `**oldest_first**` (default) — Sort ascending by `added_at` (earliest additions first in the target playlist).
- `**newest_first**` — Sort descending by `added_at` (latest additions first).

Source list order and within-playlist order are used while collecting; the final target order is this `**added_at**` sort (after deduplication). When duplicates are removed, the kept entry is the one with the **latest** `added_at` for that dedupe key.

When `replace: false` (append mode), new tracks are added after existing tracks in the playlist.

## Running Specific Collections

You can run specific collections by name using the `--collection` flag:

```bash
in_phase collect --collection drum_and_bass --collection hip_hop
```

If no collections are specified, all collections in the config will run.

## Dry Run Mode

Test your configuration without updating playlists:

```bash
in_phase collect --dry-run
```

This will show what would be done without actually modifying any playlists on Spotify.

## Common Use Cases

### Aggregate Genre Playlists

Collect all your playlists matching a pattern into a single genre collection:

```yaml
collections:
  - name: all_dnb
    target: "My DnB Collection"
    sources:
      - "DnB*"                    # All playlists starting with "DnB"
      - "Drum & Bass*"            # All playlists starting with "Drum & Bass"
      - "37i9dQZF1DXcBWIGoYBM5M"  # Specific playlist ID
    options:
      deduplicate: on_match
      replace: true               # Replace all tracks (default)
```

### Combine Multiple Discovery Playlists

Aggregate tracks from multiple discovery playlists:

```yaml
collections:
  - name: discovery_combined
    target: "All Discovery Tracks"
    sources:
      - "Weekly Discovery*"
      - "Monthly Releases"
      - "New Finds"
    options:
      deduplicate: on_id
```

### Maintain a Master Playlist

Keep a master playlist updated with tracks from multiple curated sources:

```yaml
collections:
  - name: master_collection
    target: "Master Playlist"
    sources:
      - "Favorites"
      - "Best of 2024"
      - "Live Sets*"
    options:
      deduplicate: on_match
      replace: true               # Replace all tracks (default)
```

### Append to Existing Playlist

Add tracks to an existing playlist without removing current tracks:

```yaml
collections:
  - name: append_discovery
    target: "All Discovery Tracks"
    sources:
      - "Weekly Discovery*"
      - "Monthly Releases"
    options:
      deduplicate: on_id
      replace: false              # Append to existing tracks
```

