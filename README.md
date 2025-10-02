# rkdb_dart

A Rekordbox management tool for syncing Spotify playlists with your Rekordbox database.

## Installation

```bash
fvm dart pub global activate rkdb_dart
```

## Usage

### Login to Spotify
```bash
rkdb login
```

### Sync playlists
```bash
# Sync specific playlists by ID
rkdb sync <playlist_id1> <playlist_id2>

# Or sync all playlists from config
rkdb sync
```

## Commands

- `login` - Authenticate with Spotify
- `sync` - Sync Spotify playlists to Rekordbox database

## Configuration

The tool uses a `sync_config.yaml` file to configure which playlists to sync and how to organize them. The config file is automatically created at `~/.rkdb/sync_config.yaml` on first run.

### Configuration Options

```yaml
playlists:
  # List of glob patterns to match playlist names you want to sync
  - "My DJ Sets*"     # Sync playlists starting with "My DJ Sets"
  - "Practice*"       # Sync playlists starting with "Practice"
  - "Workout Mix*"    # Sync playlists starting with "Workout Mix"

folders:
  # Organize playlists into folders in Rekordbox
  "DJ Sets":          # Folder name that will appear in Rekordbox
    playlists:
      - "My DJ Sets*" # Playlists matching this pattern go in "DJ Sets" folder
  "Practice":         # Another folder for practice sessions
    playlists:
      - "Practice*"   # Practice playlists go here
  "Personal":         # Personal listening playlists
    playlists:
      - "Workout Mix*"
      - "Chill Vibes*"

overwrite_song_keys: true  # Auto-detect and set Camelot keys from playlist names
```

### Configuration Fields Explained

**`playlists`** - Controls which Spotify playlists get synced
- Use glob patterns (`*`, `?`, `[abc]`) to match playlist names
- Only playlists matching these patterns will be synced to Rekordbox
- Common use case: Sync only your DJ playlists, not your entire Spotify library

**`folders`** - Organizes synced playlists into folders in Rekordbox
- Each key becomes a folder name in Rekordbox
- Playlists matching the patterns under each folder will be placed there
- Common use case: Keep your DJ sets separate from personal playlists, or organize by genre/event

**`overwrite_song_keys`** - Automatically detects and sets Camelot keys in Rekordbox
- Scans playlist names for Camelot key patterns (like "4A", "12B", "8A")
- Automatically sets the detected key on all songs in that playlist
- Common use case: If you name playlists like "Deep House Mix 4A", it will set all songs to key 4A
- **NOTE:** The key can appear anywhere in the playlist name, e.g. "4A Deep House Mix", "Deep House Mix 4A", or "Deep-4A-House Mix". **The first matching key will be used,** so a playlist named "Deep 4A 12B" will have all its songs set to key 4A.

### Key Features

- **Smart Playlist Filtering**: Use glob patterns to select only the playlists you want to sync
- **Automatic Organization**: Keep your Rekordbox library organized with custom folder structures
- **Camelot Key Detection**: Automatically detects and applies musical keys from playlist names
- **Intelligent Matching**: Uses fuzzy matching to find corresponding tracks in your Rekordbox library

## Requirements

- Rekordbox database access
- Spotify API credentials
- Dart/Flutter development environment