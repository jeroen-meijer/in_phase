# 💿 InPhase

[![pub.dev](https://img.shields.io/pub/v/in_phase.svg)](https://pub.dev/packages/in_phase)

A music library management tool for creating and syncing playlists between Spotify and Rekordbox.

## Installation

### Prerequisites

Both installation methods require Dart to be installed on your system:

- **macOS**: Download from [dart.dev/get-dart](https://dart.dev/get-dart) or install via Homebrew: `brew install dart`
- **Windows**: Download the installer from [dart.dev/get-dart](https://dart.dev/get-dart)
- **Linux**: Follow the instructions at [dart.dev/get-dart](https://dart.dev/get-dart)

After installing, verify it works:

```bash
dart --version
```

### Option 1: Install from pub.dev (Recommended)

The easiest way to install InPhase is using Dart's package manager:

```bash
dart pub global activate in_phase
```

After installation, you can use the tool from any directory:

```bash
in_phase login
in_phase sync
```

**Note**: Make sure `~/.pub-cache/bin` (or `%LOCALAPPDATA%\Pub\Cache\bin` on Windows) is in your system PATH.

### Option 2: Build from Source

If you want to build from source or contribute to the project:

1. **Clone the Repository**
  ```bash
   git clone https://github.com/jeroen-meijer/in_phase.git
   cd in_phase
  ```
2. **Install Dependencies**
  ```bash
   dart pub get
  ```
3. **Activate the Tool**
  ```bash
   dart pub global activate --source path .
  ```
   Or use the run script directly:
   **Note for Windows users**: You'll need to use Git Bash or WSL (Windows Subsystem for Linux) to run `.sh` scripts, or use `dart pub global activate` instead.

### Set Up Rekordbox (Optional)

**If you want to use the Rekordbox-specific features of InPhase** (such as syncing playlists to your Rekordbox database), you need to complete the setup steps below. **If you only want to use Spotify features** (like the `crawl` and `collect` commands), you can skip this entire section.

#### Prerequisites

1. **Install Rekordbox 6.0.0+**
  - Download from [rekordbox.com/en/download](https://rekordbox.com/en/download/)
  - Make sure Rekordbox is installed and you have a library set up
2. **Install SQLCipher 4.0.0+**
  SQLCipher is required to access the encrypted Rekordbox database. Install it for your platform:
   **macOS (Homebrew):**
   **Windows:**
  - Download pre-compiled binaries from [zetetic.net/sqlcipher/downloads](https://www.zetetic.net/sqlcipher/downloads/)
  - Extract and add to your system PATH
   **Linux:**
   The library will automatically detect SQLCipher in common installation locations. If you have a custom installation, you can set the path manually (see below).

#### Environment Variables (Optional)

InPhase uses the `rekorddart` package to access your Rekordbox database. Most users won't need to set these, but they're available if needed:

**SQLCIPHER_DYLIB** (Optional - only needed for custom SQLCipher installations):

```bash
# macOS/Linux
export SQLCIPHER_DYLIB=/path/to/your/libsqlcipher.dylib

# Windows PowerShell
[System.Environment]::SetEnvironmentVariable('SQLCIPHER_DYLIB', 'C:\path\to\libsqlcipher.dll', 'User')
```

**REKORDBOX_DB_KEY** (Optional - defaults to a standard key):

```bash
# macOS/Linux - add to your shell config file (~/.zshrc, ~/.bashrc, etc.)
export REKORDBOX_DB_KEY=your_key_here

# Windows PowerShell
[System.Environment]::SetEnvironmentVariable('REKORDBOX_DB_KEY', 'your_key_here', 'User')
```

#### Getting the Rekordbox Database Key

The database key is used to decrypt your Rekordbox database. You have three options:

1. **Use the default key** (Recommended for most users):
  - No action needed! InPhase will automatically use a default key if `REKORDBOX_DB_KEY` is not set.
  - This works for most standard Rekordbox installations.
2. **Download using the rekorddart tool**:
  ```bash
   # Install the rekorddart executable
   dart pub global activate rekorddart

   # Download and display the encryption key
   download_key
  ```
   Then copy the displayed key and set it as the `REKORDBOX_DB_KEY` environment variable (see above).
3. **Set manually** (if you already know your key):
  - Set the `REKORDBOX_DB_KEY` environment variable with your key (see above).

#### Additional Resources

For more detailed information, troubleshooting, or advanced configuration options, see the [rekorddart README](https://github.com/jeroen-meijer/rekorddart#getting-started).

> **⚠️ Important**: Always make a backup of your Rekordbox library before using InPhase with Rekordbox features. While InPhase is designed to be safe, modifying your Rekordbox database directly can potentially cause issues if something goes wrong.

### Set Up Spotify API Credentials

Before you can use InPhase, you need to create a Spotify app and get API credentials. This is free and only takes a few minutes:

1. **Go to the Spotify Developer Dashboard**
  - Visit [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
  - Log in with your Spotify account (or create one if you don't have one)
2. **Create a New App**
  - Click the "Create app" button
  - Fill in the app details:
    - **App name**: Choose any name (e.g., "InPhase" or "My Music Tool")
    - **App description**: Optional description
    - **Redirect URI**: This is important! Use `http://localhost:8080/callback` (or any URL you prefer, but you'll need to use the same one in the environment variable)
    - **Which API/SDKs are you planning to use?**: Select "Web API"
  - Check the agreement box and click "Save"
3. **Get Your Credentials**
  - After creating the app, you'll see your app's dashboard
  - You'll see two important values:
    - **Client ID**: A long string of letters and numbers
    - **Client Secret**: Click "View client secret" to reveal it (you'll only see this once, so save it!)
4. **Set Environment Variables**
  You need to set three environment variables with your credentials. Choose the method for your operating system:
   **macOS/Linux:**
   Add these lines to your shell configuration file (`~/.zshrc`, `~/.bashrc`, or `~/.bash_profile`):
   Then reload your shell configuration:
   **Windows:**
   Open PowerShell as Administrator and run:
   Then restart your terminal/PowerShell window.
   **Verify the variables are set:**

**Important Notes:**

- The redirect URI must match exactly what you entered in the Spotify app dashboard
- Keep your Client Secret private - don't share it or commit it to version control
- The redirect URI `http://localhost:8080/callback` is just for local development - Spotify will redirect there during authentication, but you don't need to run a web server

## Usage

### Login to Spotify

```bash
in_phase login
```

Authenticates with Spotify and caches credentials for use by other commands.

### Sync playlists

```bash
# Sync all playlists from config
in_phase sync

# Sync specific playlists by ID
in_phase sync <playlist_id1> <playlist_id2>
```

Syncs Spotify playlists to your Rekordbox database. See [SYNC_CONFIG.md](docs/SYNC_CONFIG.md) for configuration details.

### Buy missing tracks

```bash
in_phase buy
```

Opens iTunes links for tracks that were previously marked as missing during `sync`, ordered by newest first. If a track has no saved iTunes URL yet, InPhase will look one up first, then open it. The command is interactive and waits between tracks (`[enter]=next`, `[o]=open again`, `[s]=skip`, `[q]=quit`).

### Crawl for new tracks

```bash
# Run all crawl jobs
in_phase crawl
```

Automatically discovers new tracks from configured sources (playlists, artists, labels, or YouTube channels) and creates Spotify playlists. See [CRAWL_CONFIG.md](docs/CRAWL_CONFIG.md) for configuration details.

### Collect playlists

```bash
# Run all collections
in_phase collect

# Run specific collection(s)
in_phase collect --collection drum_and_bass
```

Aggregates tracks from multiple source playlists into a single target playlist. Run again to update the target with new tracks. See [COLLECT_CONFIG.md](docs/COLLECT_CONFIG.md) for configuration details.

### Convert YouTube to Spotify

```bash
# Text query → Liked Songs
in_phase convert "olivia dean so easy"

# YouTube video → target playlist (fuzzy name, ID, URI, URL, or likes)
in_phase convert "https://youtu.be/..." --add "My Playlist"
in_phase convert "https://youtu.be/..." --add likes

# YouTube playlist → new Spotify playlist
in_phase convert "https://www.youtube.com/playlist?list=PL..."

# YouTube playlist → append to existing playlist
in_phase convert "https://www.youtube.com/playlist?list=PL..." --add "Weekly Mix"

# Preview matches without writing
in_phase convert "bruno mars i just might" --dry-run
```

Matches YouTube sources to Spotify tracks via fuzzy search. Playlist URLs without `--add` create a new private Spotify playlist (`--name` / `--public` optional). Use `--replace` to clear a target playlist before adding, and `--limit` to cap how many videos are processed.

### Curate playlists

```bash
# Preview tracks and add to target playlists
in_phase curate KEYSORT
```

Preview playlist tracks one by one, add them to target playlists (key 1 = first in list, key 2 = second, etc.), or skip to the next. The playlist argument accepts ID, URI, share URL, or name (e.g. `KEYSORT`). Press **m** to toggle move mode (remove from source playlist instead of copy). Target playlists in config are plain strings (playlist ID, URI, URL, or name). Requires Spotify Premium and an active device. See [CURATE_CONFIG.md](docs/CURATE_CONFIG.md) for configuration details.

### Open config directory

```bash
in_phase config reveal
```

Opens the config directory (`~/.in_phase`) in your file manager. This directory contains all configuration files, cache files, and other data used by InPhase. This command is especially helpful for non-technical users who want to edit configuration files or see where everything is stored.

## Contributing

From a clone: `dart pub get`, then `dart format .`, `dart analyze --fatal-infos --fatal-warnings .`, and `dart test`. Pull requests should use [conventional commit](https://www.conventionalcommits.org/) **titles**; CI runs on GitHub Actions (see `.github/workflows/`).

## Requirements

- Rekordbox database access
- Spotify API credentials
- Dart SDK (for development from source)
