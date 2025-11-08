# InPhase

A music library management tool for creating and syncing playlists between Spotify and Rekordbox.

## Installation

### Step 1: Install Dart

First, you need to install Dart on your computer. Dart is the programming language this tool is built with.

- **macOS**: Download from [dart.dev/get-dart](https://dart.dev/get-dart) or install via Homebrew: `brew install dart`
- **Windows**: Download the installer from [dart.dev/get-dart](https://dart.dev/get-dart)
- **Linux**: Follow the instructions at [dart.dev/get-dart](https://dart.dev/get-dart)

After installing, verify it works by opening a terminal/command prompt and running:

```bash
dart --version
```

You should see a version number. If you get an error, make sure Dart is added to your system's PATH (the installation instructions above will guide you through this).

### Step 2: Clone the Repository

"Cloning" means downloading the source code from GitHub to your computer. You'll need Git installed (it usually comes with macOS and Linux, or download from [git-scm.com](https://git-scm.com/)).

Open a terminal/command prompt and navigate to where you want to install the tool, then run:

```bash
git clone https://github.com/jeroen-meijer/in_phase.git
cd in_phase
```

This downloads the code and moves you into the project folder.

### Step 3: Choose How to Run the Tool

You have two options:

#### Option A: Use the Run Script (Easiest)

This is the simplest way. The `run.sh` script automatically compiles and runs the tool for you:

```bash
./run.sh login
./run.sh sync
```

**Note for Windows users**: You'll need to use Git Bash or WSL (Windows Subsystem for Linux) to run `.sh` scripts, or use Option B instead.

#### Option B: Activate with Dart Pub

This makes the tool available system-wide so you can run `in_phase` from anywhere:

```bash
dart pub global activate --source path .
```

After this, you can use the tool from any directory:

```bash
in_phase login
in_phase sync
```

**Note**: Make sure `~/.pub-cache/bin` (or `%LOCALAPPDATA%\Pub\Cache\bin` on Windows) is in your system PATH. The Dart installation instructions will help you set this up.

### Step 3a: Set Up Rekordbox (Optional)

**If you want to use the Rekordbox-specific features of InPhase** (such as syncing playlists to your Rekordbox database), you need to first complete the setup steps for the `rekorddart` package.

Please follow the installation and setup instructions in the [rekorddart README](https://github.com/jeroen-meijer/rekorddart#getting-started) before continuing. The key requirements are:

- Install SQLCipher
- Set the `SQLCIPHER_DYLIB` environment variable
- (Optional) Set the `REKORDBOX_DB_KEY` environment variable or download it using the rekorddart tool

**If you only want to use Spotify features** (like the `crawl` command), you can skip this step.

### Step 4: Set Up Spotify API Credentials

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

   ```bash
   export SPOTIFY_CLIENT_ID="your_client_id_here"
   export SPOTIFY_CLIENT_SECRET="your_client_secret_here"
   export SPOTIFY_REDIRECT_URI="http://localhost:8080/callback"
   ```

   Then reload your shell configuration:

   ```bash
   source ~/.zshrc  # or ~/.bashrc, depending on your shell
   ```

   **Windows:**

   Open PowerShell as Administrator and run:

   ```powershell
   [System.Environment]::SetEnvironmentVariable('SPOTIFY_CLIENT_ID', 'your_client_id_here', 'User')
   [System.Environment]::SetEnvironmentVariable('SPOTIFY_CLIENT_SECRET', 'your_client_secret_here', 'User')
   [System.Environment]::SetEnvironmentVariable('SPOTIFY_REDIRECT_URI', 'http://localhost:8080/callback', 'User')
   ```

   Then restart your terminal/PowerShell window.

   **Verify the variables are set:**

   ```bash
   # macOS/Linux
   echo $SPOTIFY_CLIENT_ID

   # Windows PowerShell
   $env:SPOTIFY_CLIENT_ID
   ```

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

Syncs Spotify playlists to your Rekordbox database. See [SYNC_CONFIG.md](SYNC_CONFIG.md) for configuration details.

### Crawl for new tracks

```bash
# Run all crawl jobs
in_phase crawl
```

Automatically discovers new tracks from configured sources (playlists, artists, labels) and creates Spotify playlists. See [CRAWL_CONFIG.md](CRAWL_CONFIG.md) for configuration details.

### Open config directory

```bash
in_phase config reveal
```

Opens the config directory (`~/.in_phase`) in your file manager. This directory contains all configuration files, cache files, and other data used by InPhase. This command is especially helpful for non-technical users who want to edit configuration files or see where everything is stored.

## Requirements

- Rekordbox database access
- Spotify API credentials
- Dart/Flutter development environment
