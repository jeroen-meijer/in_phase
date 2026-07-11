# Curate Configuration

The `curate` command uses a `curate_config.yaml` file to configure playlist preview and track organization. The config file is automatically created at `~/.in_phase/curate_config.yaml` on first run.

**Tip:** Use `in_phase config reveal` to quickly open the config directory in your file manager, making it easy to find and edit configuration files.

## Overview

The curate command lets you preview tracks from a Spotify playlist one by one, starting each at a configurable position. You can seek within the track, add tracks to target playlists (key 1 = first in list, key 2 = second, etc.), toggle **move mode** to remove tracks from the source playlist when adding, search any of your editable playlists with **f**, or move to the next track. Requires Spotify Premium and an active Spotify device (app or web player).

## Configuration Options

```yaml
# Start each track at this position (default 1:15)
start_position: "1:15"

# Seek step in seconds when pressing ←/→ (default 15)
seek_step: 15

# When true, advance to next track after adding to one playlist.
# When false, stay so you can add to multiple playlists before continuing.
next_after_add: false

# When true, also save the track to Liked Songs when you add it to a target
# playlist (keys 1–9). The "Liked" status line only appears when the track was
# not already in Liked Songs (so pressing multiple keys does not spam it).
# auto_add_to_likes: false

# Target playlists (key 1 = first, key 2 = second, etc.; max 9)
# Each entry is a playlist identifier — resolved at session start.
targets:
  - KEYSORT
  - "chill 'n' bass"
  - 37i9dQZF1DXcBWIGoYBM5M
  - "spotify:playlist:37i9dQZF1DX4sWSpwq3LiO"
```

## Configuration Fields Explained

**`start_position`** - Where each track starts playback
- Format: `M:SS` (e.g., `"1:15"` for 1 minute 15 seconds)
- Common use case: Skip intros and start at the drop or verse

**`seek_step`** - How many seconds to seek when pressing ← or →
- Integer in seconds
- Seek is relative to current playback position, not the start position

**`next_after_add`** - Whether to advance after adding to a playlist
- `false` (default): Stay on the current track so you can add to multiple playlists
- `true`: Automatically advance to the next track after adding to one playlist

**`auto_add_to_likes`** - Also save to Liked Songs when adding to a target playlist
- `false` (default): Only the target playlist is updated
- `true`: After a successful add to a target playlist, the track is saved to Liked Songs if it was not already there; the UI only prints "Liked" when it was newly saved (not on every key press)

**`targets`** - List of playlists you can add or move tracks to
- List order determines the key: first item = key 1, second = key 2, etc. (max 9)
- Each entry is a **string** playlist identifier, resolved at session start (same rules as collect/convert):
  - Playlist ID, URI (`spotify:playlist:...`), or share URL
  - Exact playlist name (fails if ambiguous)
  - Fuzzy name match (≥ 80% score, unique winner)
- Display names in the TUI footer come from Spotify after resolution, not from config
- Press **f** to search and add/move to any editable playlist in your library (owned or collaborative). Your playlists are prefetched when the session starts so the picker opens without waiting on Spotify.

## Playlist Input

The curate command accepts a playlist as argument. You can provide:
- Playlist ID (e.g., `37i9dQZF1DXcBWIGoYBM5M`)
- URI (e.g., `spotify:playlist:37i9dQZF1DXcBWIGoYBM5M`)
- Share URL (e.g., `https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M`)
- Playlist name (e.g., `KEYSORT`) — exact or fuzzy match against your library (same rules as `targets`)

## Usage

```bash
# Curate a playlist by name
in_phase curate KEYSORT

# Curate by ID, URI, or share URL
in_phase curate <playlist>

# Use a custom config file
in_phase curate --config ./my_curate_config.yaml <playlist>

# Skip the first N tracks (e.g. when resuming)
in_phase curate --skip=5 <playlist>
```

## Keyboard Controls

- **1-9** - Add track to target playlist (1 = first in list, 2 = second, etc.); in move mode, removes from source playlist instead of copying
- **m** - Toggle move mode (footer shows `move ON` / `move OFF`). When on, keys 1–9 and **f** move the track: remove from the curated playlist (or the last target you moved to), then add to the destination. Chained moves on the same track work (e.g. P → 1 → 2). If the target already has the track, only the source is cleared
- **n**, **s**, or **space** - Next track (resets move source to the curated playlist)
- **←** / **→** - Seek backward / forward (by `seek_step` seconds)
- **r** - Restart from `start_position`
- **c** - Copy the current track's Spotify web URL
- **o** - Open the current track in Spotify (`spotify://track/…`)
- **f** - Open add-to-playlist picker (search your Spotify library, ↑/↓ to select, Enter to add or move, Esc to cancel)
- **l** - Save track to Liked Songs
- **q** - Quit
