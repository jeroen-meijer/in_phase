# InPhase example

A first session with InPhase: install it, log in to Spotify, and get your Spotify playlists into Rekordbox.

## Install

```bash
dart install in_phase
```

## Log in to Spotify

Create an app in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) with `http://localhost:8080/callback` as its redirect URI. Set its credentials and log in:

```bash
export SPOTIFY_CLIENT_ID=your_client_id
export SPOTIFY_CLIENT_SECRET=your_client_secret
export SPOTIFY_REDIRECT_URI=http://localhost:8080/callback

in_phase login
```

## Sync playlists to Rekordbox

InPhase creates its config files in `~/.in_phase` on the first run. Open that folder:

```bash
in_phase config reveal
```

In `sync_config.yaml`, list the Spotify playlists to sync by name. Glob patterns work:

```yaml
playlists:
  - "My DJ Sets*"
```

Check the config, then sync:

```bash
in_phase sync validate
in_phase sync
```

Tracks that are not in your Rekordbox library yet are marked as missing. To open their iTunes pages one by one and buy them:

```bash
in_phase buy
```

## Search and sort by key

Search your Rekordbox library:

```bash
in_phase search "artist or title"
```

Sort a Spotify playlist by Camelot key. With `--dry-run` you see the new order and the playlist stays as it is:

```bash
in_phase sort "My DJ Sets" --dry-run
```

## Find new music

Match a YouTube video to its Spotify track and save it to Liked Songs:

```bash
in_phase convert "https://youtu.be/..."
```

Go through a playlist track by track and add the ones you like to your target playlists. This needs Spotify Premium and an active device:

```bash
in_phase curate "My Inbox"
```

The [README](https://github.com/jeroen-meijer/in_phase#usage) covers every command, and the [config docs](https://github.com/jeroen-meijer/in_phase/tree/main/docs) cover the sync, crawl, collect and curate configs.
