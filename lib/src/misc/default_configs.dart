/// Default configuration files for sync, crawl, and curate commands.
///
/// These are embedded as string constants to ensure they're always available,
/// even when the package is globally activated via `dart pub global activate`.
class DefaultConfigs {
  /// Default sync configuration with commented examples.
  static const String syncConfig = '''
# Sync Configuration
# This file configures which Spotify playlists to sync to Rekordbox
# and how to organize them. See docs/SYNC_CONFIG.md for full documentation.

# List of glob patterns to match playlist names you want to sync
# Use * for wildcards, ? for single characters, [abc] for character sets
# Example: Sync all playlists starting with "DJ Sets"
#   - "DJ Sets*"
# Example: Sync playlists starting with "Practice"
#   - "Practice*"
# Example: Sync playlists starting with "Workout Mix"
#   - "Workout Mix*"
playlists: []

# Organize playlists into folders in Rekordbox
# Each key becomes a folder name, and playlists matching the patterns
# under each folder will be placed there
# Example: Create a "DJ Sets" folder for your DJ playlists
# "DJ Sets":
#   playlists:
#     - "DJ Sets*"
#     - "Live Mix*"
# Example: Create a "Practice" folder for practice sessions
# "Practice":
#   playlists:
#     - "Practice*"
# Example: Create a "Personal" folder for personal listening
# "Personal":
#   playlists:
#     - "Workout Mix*"
#     - "Chill Vibes*"
folders: {}

# Automatically detect and set Camelot keys from playlist names
# If enabled, scans playlist names for Camelot key patterns (like "4A", "12B", "8A")
# and automatically sets the detected key on all songs in that playlist
# Example: A playlist named "Deep House Mix 4A" will set all songs to key 4A
overwrite_song_keys: false

# Custom tracks allow you to insert or replace tracks in specific playlists
# This is useful for adding intro/outro tracks or replacing tracks with remixes
# Example:
# custom_tracks:
#   # Spotify playlist ID (find it in the playlist URL)
#   "37i9dQZF1DXcBWIGoYBM5M":
#     # Insert a track at a specific position
#     - rekordbox_id: "12345"  # Rekordbox song ID
#       type: insert
#       position: 1  # 1-based position (1 = first track)
#     
#     # Replace a track at a specific position
#     - rekordbox_id: "67890"
#       type: replace
#       position: 5
#     
#     # Insert a track relative to another track
#     - rekordbox_id: "11111"
#       type: insert
#       target: "12345"  # Target Rekordbox song ID
#       index: 1  # Insert 1 position after the target track
custom_tracks: {}
''';

  /// Default crawl configuration with commented examples.
  static const String crawlConfig = '''
# Crawl Configuration
# This file configures automated playlist creation from Spotify sources.
# See docs/CRAWL_CONFIG.md for full documentation.

# Optional section for defining YAML anchors (reusable IDs)
# This makes it easier to reference the same playlist/artist/label in multiple jobs
# Example:
# _notes:
#   # Define playlist IDs that you'll reference in jobs
#   playlists:
#     new_releases: &playlist_new_releases '37i9dQZF1DXcBWIGoYBM5M'
#   
#   # Define artist IDs
#   artists:
#     favorite_artist: &artist_favorite '4UJP03mzC9b90Qq1TqavvN'
#   
#   # Define label names
#   labels:
#     favorite_label: &label_favorite "Your Label Name"
#   
#   # Define YouTube channel handles or IDs
#   youtube_channels:
#     favorite_channel: &youtube_favorite '@ChannelName'

# List of crawl jobs to run
# Each job creates a playlist from configured sources
# Example: Weekly discovery playlist from playlists and artists
# - name: weekly_discovery
#   output_playlist:
#     name: 'Weekly Discovery - Week {week_num} {year}'
#     description: 'Fresh tracks from {real_playlist_count} playlists and {real_artist_source_count} artists'
#     public: false
#     # Optional: Update existing playlist instead of creating new
#     # id: '37i9dQZF1DXcBWIGoYBM5M'  # Playlist ID, URI, or share URL
#   filters:
#     date_range: 7  # Last 7 days (backward compatible with added_between_days)
#     # Or use other formats:
#     # date_range: "today"  # Just today
#     # date_range: "current_week"  # Current week (Monday-Sunday)
#     # date_range: "current_month"  # Current month (1st to last day)
#     # date_range: "current_year"  # Current year (Jan 1 to Dec 31)
#     # date_range: { weeks: 2 }  # Last 2 weeks
#     # date_range: { months: 1 }  # Last 1 month
#     # date_range: { start: "2024-07-20", end: "2024-07-28" }  # Specific dates
#   options:
#     deduplicate: on_match  # Remove duplicate tracks by artist/title match
#     add_playlist_tracks_based_on: release_date  # Use release date for filtering
#     update_mode: replace  # How to update target playlist: 'replace' or 'append'
#   inputs:
#     playlists:
#       - *playlist_new_releases  # Reference anchor from _notes
#       # - '37i9dQZF1DXcBWIGoYBM5M'  # Or use playlist ID directly
#     artists:
#       - *artist_favorite  # Reference anchor from _notes
#       # - '4UJP03mzC9b90Qq1TqavvN'  # Or use artist ID directly
#     labels:
#       - *label_favorite  # Reference anchor from _notes
#       # - "Your Label Name"  # Or use label name directly
#     youtube_channels:
#       - *youtube_favorite  # Reference anchor from _notes
#       # - '@ChannelName'  # Or use channel handle directly
# 
# Example: Monthly release roundup with cover image
# - name: monthly_releases
#   output_playlist:
#     name: '{month} {year} Releases'
#     description: 'New releases from {real_label_source_count} labels'
#     public: false
#     # Optional: Update existing playlist instead of creating new
#     # id: '37i9dQZF1DXcBWIGoYBM5M'  # Playlist ID, URI, or share URL
#   cover:
#     image: 'cover.jpg'  # Place cover.jpg in the same directory as this config
#     caption: '{month} {year}\n#{month_num}'
#   filters:
#     date_range: { months: 1 }  # Last 1 month
#     # Or: date_range: 30  # Last 30 days
#   options:
#     deduplicate: on_id  # Remove duplicate tracks by Spotify ID
#   inputs:
#     labels:
#       - "Label Name 1"
#       - "Label Name 2"
jobs: []
''';

  /// Default curate configuration.
  static const String curateConfig = '''
# Curate Configuration
# Usage: in_phase curate <playlist> [--skip=N]
# Playlist: ID, URI (spotify:playlist:...), or share URL (https://open.spotify.com/playlist/...)
# See docs/CURATE_CONFIG.md for full documentation.

# Start each track at this position (default 1:15)
start_position: "1:15"

# Seek step in seconds when pressing ←/→
seek_step: 15

# When true, advance to next track after adding to one playlist.
# When false, stay so you can add to multiple playlists before continuing.
next_after_add: false

# When true, also add the track to Liked Songs when you add it to a target
# playlist. "Liked" is only reported if it was not already saved.
# auto_add_to_likes: false

# Target playlists to add to (key 1 = first, key 2 = second, etc.)
# Replace with your playlist ID, URI, or share URL
targets:
  - id: "YOUR_PLAYLIST_ID_1"
    name: "Favorites"
  - id: "YOUR_PLAYLIST_ID_2"
    name: "To Review"
''';

  /// Default collect configuration with commented examples.
  static const String collectConfig = '''
# Collect Configuration
# This file configures playlist aggregation: combine tracks from multiple
# Spotify playlists into a single target playlist. See docs/COLLECT_CONFIG.md for full documentation.

# Optional section for defining YAML anchors (reusable playlist IDs)
# Example:
# _notes:
#   playlists:
#     liquicity: &playlist_liquicity '5GH6XFP11JTr9wzwsNESwY'

# List of collections. Each aggregates multiple source playlists into one target.
# Example: Aggregate DnB playlists into "My DnB Collection"
# collections:
#   - name: drum_and_bass
#     target: "37i9dQZF1DXcBWIGoYBM5M"   # Playlist ID, URI, share URL, or exact name
#     description: "Last updated: {real_datetime}"  # Optional description template
#     sources:
#       - *playlist_liquicity            # YAML anchor reference
#       - "37i9dQZF1DXcBWIGoYBM5M"      # Direct playlist ID
#       - "DnB Releases*"                # Glob pattern (matches playlist names)
#       - "Liquid Drum & Bass"           # Exact playlist name
#     options:
#       deduplicate: on_match            # on_id | on_match (default: on_id)
#       replace: true                     # Replace all tracks (true) or append (false). Default: true
collections: []
''';
}
