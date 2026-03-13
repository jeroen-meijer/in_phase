# Crawl Configuration

The `crawl` command uses a `crawl_config.yaml` file to configure automated playlist creation from Spotify sources. The config file is automatically created at `~/.in_phase/crawl_config.yaml` on first run.

**Tip:** Use `in_phase config reveal` to quickly open the config directory in your file manager, making it easy to find and edit configuration files.

## Overview

The crawl command searches Spotify for new tracks from configured sources (playlists, artists, labels, or YouTube channels) and automatically creates playlists with those tracks. This is useful for creating weekly discovery playlists, release roundups, or curated collections based on specific sources.

## Configuration Structure

The config file has two main sections:

1. **`_notes`** - Optional section for defining YAML anchors (reusable IDs). Is **not** used by the tool but is useful for referencing playlist and artist IDs in the jobs section.
2. **`jobs`** - List of crawl jobs to run. Each job is a single automated playlist creation task.

### Example Configuration

```yaml
_notes:
  playlists:
    my_playlist: &playlist_my_playlist '5GH6XFP11JTr9wzwsNESwY'
  artists:
    my_artist: &my_artist 4UJP03mzC9b90Qq1TqavvN
  labels:
    my_label: &label_my_label "Critical Music"

jobs:
  - name: weekly_discovery
    output_playlist:
      name: 'Weekly Discovery - Week {week_num} {year}'
      description: 'Fresh tracks from {real_playlist_count} playlists and {real_artist_source_count} artists'
      public: false
    cover:
      image: 'cover.jpg'
      caption: "Weekly Discovery\n{year} - #{week_num}"
    filters:
      date_range: 7  # Last 7 days
    options:
      deduplicate: on_match
      add_playlist_tracks_based_on: release_date
    # Optional: Update existing playlist instead of creating new
    # target_playlist: '37i9dQZF1DXcBWIGoYBM5M'
    inputs:
      playlists:
        - *playlist_my_playlist
      artists:
        - *my_artist
      labels:
        - *label_my_label
      youtube_channels:
        - '@SkankandbassUK'
```

## Job Configuration

Each job in the `jobs` array defines a single automated playlist creation task.

### Required Fields

- **`name`** - Unique identifier for the job (used in logs and reports)
- **`output_playlist`** - Configuration for the playlist to create or update
  - **`name`** - Playlist name template (supports template variables)
  - **`description`** - Optional playlist description template
  - **`public`** - Whether the playlist should be public (default: `false`, only used when creating new playlist)
- **`target_playlist`** - Optional playlist ID, URI, or share URL to update instead of creating new. If provided, the existing playlist will be updated with new tracks, name, description, and cover image.
- **`filters`** - Track filtering options
  - **`date_range`** - Date range configuration (see [Date Range Formats](#date-range-formats) below)
  - **`added_between_days`** - *Deprecated: Use `date_range` instead.* Number of days to look back for tracks
- **`inputs`** - Sources to collect tracks from
  - **`playlists`** - List of Spotify playlist IDs (optional)
  - **`artists`** - List of Spotify artist IDs (optional)
  - **`labels`** - List of label names (optional)
  - **`youtube_channels`** - List of YouTube channel handles or IDs (optional, e.g., `@SkankandbassUK` or `UCCXCgbZcT7rjU0vS0POSWIQ`)

### Optional Fields

- **`cover`** - Cover image configuration
  - **`image`** - Filename of cover image (relative to config file directory)
  - **`caption`** - Optional caption text template to overlay on image
- **`options`** - Processing options
  - **`deduplicate`** - Deduplication mode: `on_id` or `on_match` (optional)
  - **`add_playlist_tracks_based_on`** - Which date to use for filtering playlist tracks: `added_date` or `release_date` (default: `release_date`)
  - **`update_mode`** - How to update target playlist: `replace` or `append` (default: `replace`, only applies when `target_playlist` is specified)

## Template Variables

Playlist names, descriptions, and cover captions support template variables enclosed in curly braces `{}`. Available variables:

### Date Variables
- `{week_num}` - Week number of the year (1-53)
- `{year}` - Full year (e.g., 2024)
- `{year_short}` - Two-digit year (e.g., 24)
- `{month}` - Full month name (e.g., January)
- `{month_name}` - Full month name (same as `month`)
- `{month_name_short}` - Short month name (e.g., Jan)
- `{month_num}` - Two-digit month (01-12)
- `{date}` - Full date (YYYY-MM-DD format)
- `{quarter}` - Quarter (Q1-Q4)

### Date Range Variables
- `{date_range_start_date}` - Start date of the date range (YYYY-MM-DD)
- `{date_range_end_date}` - End date of the date range (YYYY-MM-DD)
- `{date_range_start_short}` - Short start date (e.g., Jan 15)
- `{date_range_end_short}` - Short end date (e.g., Jan 22)
- `{date_range_days}` - Number of days in the date range
- `{date_range_month}` - Month name(s) for the date range
- `{date_range_cross_month}` - Cross-month date range string

### Week Variables
- `{week_start_date}` - Start date of the week (Monday)
- `{week_end_date}` - End date of the week (Sunday)

### Real-Time Variables (Current Date/Time)
- `{real_date}` - Current date (YYYY-MM-DD)
- `{real_year}` - Current year
- `{real_month}` - Current month name
- `{real_month_num}` - Current two-digit month
- `{real_year_short}` - Current two-digit year
- `{real_week_num}` - Current week number
- `{real_day}` - Current day of month
- `{real_day_name}` - Current day name (e.g., Monday)
- `{real_day_name_short}` - Current short day name (e.g., Mon)
- `{real_time}` - Current time (HH:MM)
- `{real_time_with_seconds}` - Current time (HH:MM:SS)
- `{real_datetime}` - Current date and time (YYYY-MM-DD HH:MM)
- `{real_datetime_full}` - Current date and time (YYYY-MM-DD HH:MM:SS)
- `{real_timestamp}` - Unix timestamp
- `{real_week_start_date}` - Start of current week
- `{real_week_end_date}` - End of current week

### Content Statistics
- `{track_count}` - Number of tracks in the playlist
- `{real_artist_count}` - Number of unique artists in tracks
- `{real_album_count}` - Number of unique albums in tracks
- `{real_playlist_count}` - Number of unique playlist sources
- `{real_artist_source_count}` - Number of unique artist sources
- `{real_label_source_count}` - Number of unique label sources
- `{real_youtube_channel_source_count}` - Number of unique YouTube channel sources

### Job Configuration Variables
- `{job_playlist_count}` - Number of playlists configured in job
- `{job_artist_count}` - Number of artists configured in job
- `{job_label_count}` - Number of labels configured in job
- `{job_youtube_channel_count}` - Number of YouTube channels configured in job
- `{job_name}` - Job name
- `{job_name_pretty}` - Job name formatted for display

### Legacy Aliases
- `{playlist_count}` - Same as `job_playlist_count`
- `{artist_count}` - Same as `job_artist_count`
- `{label_count}` - Same as `job_label_count`

## Using YAML Anchors

YAML anchors allow you to define reusable IDs in the `_notes` section and reference them in jobs. This makes it easier to manage large configurations.

```yaml
_notes:
  playlists:
    liquicity_releases: &playlist_liquicity '5GH6XFP11JTr9wzwsNESwY'
  artists:
    flint_and_figure: &flint_and_figure 4UJP03mzC9b90Qq1TqavvN
  labels:
    critical_music: &label_critical "Critical Music"
  youtube_channels:
    skankandbass: &youtube_skankandbass '@SkankandbassUK'

jobs:
  - name: liquid_weekly
    # ... other config ...
    inputs:
      playlists:
        - *playlist_liquicity  # Reference the anchor
      artists:
        - *flint_and_figure
      labels:
        - *label_critical
      youtube_channels:
        - *youtube_skankandbass
```

## Date Range Formats

The `date_range` filter determines which date range to use for track filtering. It supports multiple formats:

### Simple Formats

1. **Integer** (backward compatible with `added_between_days`):
   ```yaml
   filters:
     date_range: 7  # Last 7 days
   ```

2. **String shortcuts**:
   ```yaml
   filters:
     date_range: "today"  # Just today
     date_range: "current_week"  # Current week (Monday-Sunday)
     date_range: "current_month"  # Current month (1st to last day)
     date_range: "current_year"  # Current year (Jan 1 to Dec 31)
   ```

3. **Time units back** (consistent format):
   ```yaml
   filters:
     date_range:
       days: 7  # Last 7 days (same as integer format)
     date_range:
       weeks: 2  # Last 2 weeks
     date_range:
       months: 1  # Last 1 month
   ```

4. **Absolute date range**:
   ```yaml
   filters:
     date_range:
       start: "2024-07-20"
       end: "2024-07-28"
   ```

### Date Filtering Behavior

The date range determines how far back to look for tracks:

- For **playlists**: Uses either the track's release date or when it was added to the playlist (controlled by `add_playlist_tracks_based_on`)
- For **artists**: Uses the track's release date
- For **labels**: Uses the track's release date
- For **YouTube channels**: Uses the video's publish/upload date

### CLI Flag Overrides

You can override the date range using CLI flags:

- **`--end-date YYYY-MM-DD`**: Sets the reference date for relative ranges (e.g., `date_range: "current_month"` resolves relative to this date)
- **`--start-date YYYY-MM-DD`**: Overrides the calculated start date

Examples:
- `date_range: 7` with `--end-date 2024-07-15` → resolves to July 9-15 (7 days ending on July 15)
- `date_range: "current_month"` with `--end-date 2024-07-15` → resolves to July 2024

### Migration from `added_between_days`

The `added_between_days` field is deprecated but still works for backward compatibility. To migrate:

```yaml
# Old format
filters:
  added_between_days: 7

# New format (equivalent)
filters:
  date_range: 7
```

## Deduplication

The `deduplicate` option controls how duplicate tracks are handled:

- **`on_id`** - Remove tracks with duplicate Spotify track IDs
- **`on_match`** - Remove tracks with matching artist names and track titles (fuzzy matching)
- Not specified - No deduplication

## Playlist Track Date Mode

The `add_playlist_tracks_based_on` option determines which date to use when filtering tracks from playlists:

- **`release_date`** (default) - Use the track's album release date
- **`added_date`** - Use when the track was added to the playlist

This is useful if you want to include tracks that were recently added to a playlist, even if they were released earlier.

## Target Playlist

By default, each crawl job creates a new playlist. However, you can update an existing playlist instead by specifying `target_playlist` at the job level:

```yaml
- name: weekly_discovery
  output_playlist:
    name: 'Weekly Discovery - Week {week_num} {year}'
    description: 'Fresh tracks from {real_playlist_count} playlists'
  target_playlist: '37i9dQZF1DXcBWIGoYBM5M'  # Playlist ID, URI, or share URL
  filters:
    date_range: 7
  options:
    update_mode: replace  # or 'append' to add tracks without clearing
```

The `target_playlist` field accepts:
- **Playlist ID**: `37i9dQZF1DXcBWIGoYBM5M`
- **Spotify URI**: `spotify:playlist:37i9dQZF1DXcBWIGoYBM5M`
- **Share URL**: `https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M`

When `target_playlist` is specified:
- The playlist's name and description are updated (using templates)
- The playlist's cover image is updated (if configured)
- The playlist must exist and you must have edit access (you own it or have collaborative edit access)
- The `public` field is ignored (the playlist keeps its existing visibility)

### Update Modes

The `update_mode` option in `options` controls how tracks are updated:

- **`replace`** (default): Clear all existing tracks and replace with new tracks
- **`append`**: Add new tracks without clearing existing ones. Tracks that are already in the playlist are skipped.

**Note:** If `update_mode` is set to `append` but no `target_playlist` is specified, a warning will be shown (since a new playlist is created anyway, append mode has no effect).

If `target_playlist` is not specified, a new playlist is created with the configured name, description, and visibility.

## Cover Images

Cover images are generated automatically if configured. The image file should be placed in the same directory as your config file. The caption text is overlaid on the image and supports template variables.

Cover images are saved to `~/.in_phase/build/generated_covers/` and uploaded to Spotify automatically.

## Running Specific Jobs

You can run specific jobs by name using the `--job` flag:

```bash
in_phase crawl --job liquid_weekly --job underground_weekly
```

If no jobs are specified, all jobs in the config will run.

## Dry Run Mode

Test your configuration without creating playlists:

```bash
in_phase crawl --dry-run
```

This will show what would be created without actually creating playlists on Spotify.

## Custom Date Ranges

Override the job's date range with custom dates:

```bash
in_phase crawl --start-date 2024-01-01 --end-date 2024-01-31
```

Note that the end date is **inclusive**, meaning that the tracks added on the end date **will** be included in the playlist.

This overrides the `date_range` setting for all jobs. The `--end-date` becomes the reference date for relative ranges (like "current_month"), and `--start-date` overrides the calculated start date.

