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

## Requirements

- Rekordbox database access
- Spotify API credentials
- Dart/Flutter development environment