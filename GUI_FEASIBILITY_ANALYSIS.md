# GUI Feasibility Analysis for InPhase

## Executive Summary

This document analyzes the feasibility of building a GUI for the InPhase music library management tool, with assistance from an LLM (Composer 1). The analysis covers technical feasibility, required architectural changes, and technology stack recommendations.

---

## 1. Understanding InPhase

### 1.1 Current Architecture

InPhase is a **command-line tool** written in **Dart** that manages music libraries by:

- **Syncing playlists** from Spotify to Rekordbox
- **Crawling** Spotify for new tracks from configured sources (playlists, artists, labels, YouTube channels)
- **Searching** Rekordbox library
- **Managing cues** in Rekordbox tracks
- **Configuring** sync and crawl jobs via YAML files

### 1.2 Key Components

**Commands:**

- `login` - Spotify OAuth authentication
- `sync` - Sync Spotify playlists to Rekordbox
- `crawl` - Discover and create playlists from sources
- `search` - Search Rekordbox library (interactive)
- `cues sync` - Sync cues between tracks
- `config reveal` - Open config directory

**Core Infrastructure:**

- **Spotify API integration** (`lib/src/spotify/`) - OAuth, API calls, caching
- **Database layer** (`lib/src/database/`) - Drift-based SQLite for caching sync/crawl data
- **Rekordbox integration** - Via `rekorddart` package (SQLCipher database access)
- **Configuration** - YAML-based configs for sync and crawl jobs
- **Report generation** - Markdown reports for sync/crawl operations

### 1.3 Current Data Flow

```
CLI Command → Command Class → Spotify API / Rekordbox DB → Results → Console Output / Reports
```

---

## 2. LLM Capabilities Assessment (Composer 1)

### 2.1 Performance Characteristics

Based on available information about Composer 1:

**Strengths:**

- **Fast generation**: ~250 tokens/second (4x faster than comparable models)
- **Mixture-of-experts architecture**: Efficient for code generation tasks
- **Tool usage**: Effective at using semantic search, file editors, terminal commands
- **Real-world training**: Trained in actual development environments
- **Fast Frontier**: Matches intelligence of mid-frontier systems (Claude Haiku 4.5, Gemini Flash 2.5)

**Limitations:**

- **No public benchmarks**: Performance claims not independently verified
- **Internal evaluation**: Uses proprietary "Cursor Bench" instead of standard benchmarks
- **Speed-focused**: Optimized for speed, may trade off some reasoning depth

### 2.2 Framework Experience Assessment

**Dart/Flutter:**

- ✅ **High confidence**: Composer 1 is trained on real codebases, Flutter is widely used
- ✅ **Strong ecosystem**: Flutter has excellent GUI capabilities, state management, and tooling
- ✅ **Codebase familiarity**: Already working with Dart codebase, understands patterns

**TypeScript/React/Next.js:**

- ✅ **High confidence**: JavaScript/TypeScript is the most common language in training data
- ✅ **Web frameworks**: React, Next.js, Vue are well-represented in training
- ⚠️ **Cross-platform**: Would require Electron or Tauri for desktop app

**Rust (GUI frameworks):**

- ⚠️ **Moderate confidence**: Rust is less common in training data than JS/Dart
- ⚠️ **Framework diversity**: Many Rust GUI frameworks (Tauri, egui, iced, slint) - less standardized
- ✅ **Performance**: Excellent for native performance, but may be overkill

**Recommendation**: **Dart/Flutter** offers the best balance of LLM capability, codebase consistency, and cross-platform GUI capabilities.

---

## 3. Feasibility Assessment

### 3.1 Overall Feasibility: **HIGH** ✅

**Why it's feasible:**

1. **Well-structured codebase**: Commands are cleanly separated, making extraction easier
2. **Clear separation of concerns**: Business logic is separate from CLI presentation
3. **Existing abstractions**: Database layer, API layer already abstracted
4. **LLM capabilities**: Composer 1 can handle Flutter/Dart GUI development effectively
5. **Human assistance**: Can handle complex integration points, testing, and edge cases

**Challenges:**

1. **OAuth flow**: Browser-based authentication needs GUI adaptation
2. **Long-running operations**: Sync/crawl operations need progress indicators
3. **Configuration UI**: YAML configs need visual editors
4. **Real-time updates**: Need to show progress for async operations

### 3.2 Required Architectural Changes

#### 3.2.1 API Layer Separation

**Current State:**

- Commands directly call Spotify API and Rekordbox database
- Business logic mixed with CLI presentation (logging, progress)
- No clear API boundary

**Required Changes:**

1. **Extract Service Layer**

   ```
   lib/src/
     services/
       spotify_service.dart      # Spotify API operations
       rekordbox_service.dart    # Rekordbox operations
       sync_service.dart         # Sync orchestration
       crawl_service.dart        # Crawl orchestration
       search_service.dart       # Search operations
   ```

2. **Separate Business Logic from Presentation**

   - Commands should delegate to services
   - Services return structured data (not formatted strings)
   - CLI layer formats output, GUI layer displays in widgets

3. **Event/Stream Architecture**
   - Long-running operations emit progress events
   - GUI can subscribe to progress streams
   - Enables real-time UI updates

**Example Refactoring:**

```dart
// Current (sync_command.dart)
@override
Future<int> run() async {
  // ... 400+ lines of mixed logic and presentation
  log.info('Syncing playlist...');
  // ... business logic
  log.info('Done');
}

// Proposed (sync_service.dart)
class SyncService {
  Stream<SyncProgress> syncPlaylists({
    List<SpotifyPlaylistId>? playlistIds,
  }) async* {
    yield SyncProgress.started();
    // ... business logic
    yield SyncProgress.playlistStarted(name: '...');
    // ... more logic
    yield SyncProgress.completed(report: syncReport);
  }
}
```

#### 3.2.2 State Management

**Requirements:**

- Track sync/crawl progress
- Manage configuration state
- Handle authentication state
- Cache management UI

**Recommended Approach:**

- **Riverpod** or **Provider** for state management
- **StreamBuilder** widgets for real-time updates
- **StateNotifier** for complex state logic

#### 3.2.3 Configuration Management

**Current:** YAML files edited manually

**GUI Needs:**

- Visual editor for sync config (playlist patterns, folders, Camelot keys)
- Visual editor for crawl config (jobs, sources, templates)
- Form validation
- Preview of what will happen

**Approach:**

- Keep YAML as storage format
- Load into Dart models (`SyncConfig`, `CrawlConfig`)
- Provide GUI forms to edit models
- Save back to YAML

#### 3.2.4 Authentication Flow

**Current:** Browser-based OAuth with URL paste

**GUI Needs:**

- Embedded browser/webview for OAuth
- Or system browser with callback handling
- Token storage and refresh management

**Solution:**

- Use `url_launcher` or `webview_flutter` for OAuth
- Handle redirect URI in app
- Store credentials securely (already handled by `doos` package)

---

## 3.5 Exposing an API Surface for Separate Flutter App

This section provides concrete, actionable steps to expose an API surface from `in_phase` that a separate Flutter app can consume. This approach allows the GUI to be developed independently while reusing the core business logic.

### 3.5.1 API Design: Single InPhase Class

**Design Principle:** Expose a single `InPhase` class that encapsulates all functionality. This provides a clean, cohesive API surface that's easy to use and understand.

**Benefits:**
- ✅ Single entry point - no need to manage multiple service instances
- ✅ Encapsulated state - authentication, database connections managed internally
- ✅ Simple initialization - one constructor/factory method
- ✅ Clear ownership - one instance manages all resources
- ✅ Easy to dispose - single `dispose()` method cleans up everything

### 3.5.2 Proposed API Surface

**File:** `lib/src/api/in_phase.dart`

```dart
import 'dart:async';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/spotify/types.dart';
import 'package:spotify/spotify.dart';

/// Progress events for sync operations
sealed class SyncProgress {
  const SyncProgress();
}

class SyncProgressStarted extends SyncProgress {
  const SyncProgressStarted();
}

class SyncProgressPlaylistStarted extends SyncProgress {
  final String playlistName;
  final SpotifyPlaylistId playlistId;

  const SyncProgressPlaylistStarted({
    required this.playlistName,
    required this.playlistId,
  });
}

class SyncProgressTrackProcessed extends SyncProgress {
  final String trackName;
  final List<String> artistNames;
  final bool matched;
  final String? rekordboxSongId;

  const SyncProgressTrackProcessed({
    required this.trackName,
    required this.artistNames,
    required this.matched,
    this.rekordboxSongId,
  });
}

class SyncProgressPlaylistCompleted extends SyncProgress {
  final SyncPlaylistReport report;

  const SyncProgressPlaylistCompleted({
    required this.report,
  });
}

class SyncProgressCompleted extends SyncProgress {
  final SyncReport report;

  const SyncProgressCompleted({
    required this.report,
  });
}

class SyncProgressError extends SyncProgress {
  final String message;
  final Object? error;

  const SyncProgressError({
    required this.message,
    this.error,
  });
}

/// Progress events for crawl operations
sealed class CrawlProgress {
  const CrawlProgress();
}

class CrawlProgressJobStarted extends CrawlProgress {
  final String jobName;
  const CrawlProgressJobStarted({required this.jobName});
}

class CrawlProgressJobCompleted extends CrawlProgress {
  final CrawlJobReport report;
  const CrawlProgressJobCompleted({required this.report});
}

class CrawlProgressCompleted extends CrawlProgress {
  final CrawlReport report;
  const CrawlProgressCompleted({required this.report});
}

class CrawlProgressError extends CrawlProgress {
  final String message;
  final Object? error;
  const CrawlProgressError({required this.message, this.error});
}

/// Search result from Rekordbox
class SearchResult {
  final String trackId;
  final String title;
  final String artist;
  final String? album;
  final int? bpm;
  final int? lengthSeconds;
  final int hotCueCount;
  final int memoryCueCount;

  const SearchResult({
    required this.trackId,
    required this.title,
    required this.artist,
    this.album,
    this.bpm,
    this.lengthSeconds,
    required this.hotCueCount,
    required this.memoryCueCount,
  });
}

/// Main API class for InPhase functionality
class InPhase {
  final SpotifyApi _spotifyApi;
  final RekordboxDatabase? _rbDb;
  final AppDatabase _syncDb;
  final RequestPool _requestPool;
  bool _disposed = false;

  InPhase._({
    required SpotifyApi spotifyApi,
    RekordboxDatabase? rbDb,
    required AppDatabase syncDb,
    required RequestPool requestPool,
  })  : _spotifyApi = spotifyApi,
        _rbDb = rbDb,
        _syncDb = syncDb,
        _requestPool = requestPool;

  /// Creates an InPhase instance with authenticated Spotify API
  ///
  /// [spotifyApi] - Authenticated Spotify API instance (use [spotifyLogin] to get this)
  /// [rekordboxDbPath] - Optional path to Rekordbox database. If null, Rekordbox features will be disabled.
  static Future<InPhase> create({
    required SpotifyApi spotifyApi,
    String? rekordboxDbPath,
  }) async {
    // Initialize sync database
    final syncDb = AppDatabase.fromCacheDbFile();

    // Initialize request pool
    final requestPool = Zonable.fromZone<RequestPool>();

    // Initialize Rekordbox database if path provided
    RekordboxDatabase? rbDb;
    if (rekordboxDbPath != null) {
      rbDb = await RekordboxDatabase.connect();
    }

    return InPhase._(
      spotifyApi: spotifyApi,
      rbDb: rbDb,
      syncDb: syncDb,
      requestPool: requestPool,
    );
  }

  /// Checks if user is authenticated with Spotify
  bool get isAuthenticated {
    _checkDisposed();
    // Check if credentials are valid
    return true; // Implementation checks token validity
  }

  /// Gets the current Spotify user info
  Future<User> getCurrentUser() async {
    _checkDisposed();
    return await _spotifyApi.me.get();
  }

  /// Gets all Spotify playlists for the authenticated user
  Future<List<PlaylistSimple>> getPlaylists() async {
    _checkDisposed();
    return await _spotifyApi.playlists.me.all(50);
  }

  /// Syncs playlists from Spotify to Rekordbox
  ///
  /// Emits progress events via the returned stream. If [playlistIds] is provided,
  /// syncs only those playlists. Otherwise, syncs all playlists matching the sync config patterns.
  Stream<SyncProgress> syncPlaylists({
    List<String>? playlistIds,
  }) async* {
    _checkDisposed();
    _checkRekordboxAvailable();

    yield const SyncProgressStarted();

    try {
      final syncConfig = await SyncConfig.fromFile(Constants.syncConfigFile);

      // Get playlists to sync
      final List<PlaylistSimple> spPlaylists;
      if (playlistIds != null) {
        final ids = playlistIds.map((id) => SpotifyPlaylistId(id)).toList();
        spPlaylists = await _getPlaylistsByIds(ids);
      } else {
        spPlaylists = await _getPlaylistsFromConfig(syncConfig);
      }

      final playlistReports = <SyncPlaylistReport>[];

      // Process each playlist
      for (final spPlaylist in spPlaylists) {
        yield SyncProgressPlaylistStarted(
          playlistName: spPlaylist.name!,
          playlistId: SpotifyPlaylistId(spPlaylist.id!),
        );

        // ... existing sync logic from SyncCommand.run() ...
        // Extract the core logic, yield progress events instead of logging

        final report = await _syncPlaylist(
          spPlaylist: spPlaylist,
          syncConfig: syncConfig,
        );

        playlistReports.add(report);
        yield SyncProgressPlaylistCompleted(report: report);
      }

      final syncReport = SyncReport(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        playlistReports: playlistReports,
      );

      yield SyncProgressCompleted(report: syncReport);
    } catch (e, stackTrace) {
      yield SyncProgressError(
        message: 'Sync failed: $e',
        error: e,
      );
    }
  }

  /// Crawls Spotify for new tracks and creates playlists
  ///
  /// [jobNames] - Optional list of job names to run. If null, runs all jobs.
  /// [startDate] - Optional custom start date (overrides job's added_between_days)
  /// [endDate] - Optional custom end date (defaults to today)
  /// [dryRun] - If true, doesn't create playlists, just shows what would be done
  Stream<CrawlProgress> crawl({
    List<String>? jobNames,
    DateTime? startDate,
    DateTime? endDate,
    bool dryRun = false,
  }) async* {
    _checkDisposed();

    // ... existing crawl logic from CrawlCommand.run() ...
    // Extract the core logic, yield progress events instead of logging
  }

  /// Searches Rekordbox library for tracks
  ///
  /// [query] - Search query (track name, artist, or Rekordbox track ID)
  /// [limit] - Maximum number of results to return (default: 20)
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    _checkDisposed();
    _checkRekordboxAvailable();

    // ... existing search logic from SearchCommand ...
    // Return structured results instead of logging
  }

  /// Gets the current sync configuration
  Future<SyncConfig> getSyncConfig() async {
    _checkDisposed();
    return await SyncConfig.fromFile(Constants.syncConfigFile);
  }

  /// Saves the sync configuration
  Future<void> saveSyncConfig(SyncConfig config) async {
    _checkDisposed();
    await config.saveToFile(Constants.syncConfigFile);
  }

  /// Gets the current crawl configuration
  Future<CrawlConfig> getCrawlConfig() async {
    _checkDisposed();
    return await CrawlConfig.fromFile(Constants.crawlConfigFile);
  }

  /// Saves the crawl configuration
  Future<void> saveCrawlConfig(CrawlConfig config) async {
    _checkDisposed();
    await config.saveToFile(Constants.crawlConfigFile);
  }

  /// Gets sync report history
  Future<List<SyncReport>> getSyncHistory({int? limit}) async {
    _checkDisposed();
    // Implementation: read reports from disk
    return [];
  }

  /// Gets crawl report history
  Future<List<CrawlReport>> getCrawlHistory({int? limit}) async {
    _checkDisposed();
    // Implementation: read reports from disk
    return [];
  }

  /// Disposes of all resources (databases, connections, etc.)
  ///
  /// Call this when done using the InPhase instance to clean up resources.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await (await _spotifyApi.client).close();
    await _rbDb?.close();
    await _syncDb.close();
    _requestPool.clear();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('InPhase instance has been disposed');
    }
  }

  void _checkRekordboxAvailable() {
    if (_rbDb == null) {
      throw StateError(
        'Rekordbox database not available. '
        'Provide rekordboxDbPath when creating InPhase instance.',
      );
    }
  }

  // ... private helper methods ...
}
```

### 3.5.3 Export Public API

**File:** `lib/in_phase_api.dart` (at root)

```dart
/// Public API for consuming InPhase functionality in external applications
library in_phase_api;

export 'src/api/in_phase.dart';
export 'src/entities/entities.dart';
export 'src/spotify/types.dart';
export 'src/spotify/spotify.dart' show spotifyLogin;
```

### 3.5.4 Usage Example for Separate Flutter App

**In the GUI app:**

```dart
import 'package:flutter/material.dart';
import 'package:in_phase/in_phase_api.dart';
import 'dart:async';

class SyncScreen extends StatefulWidget {
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  InPhase? _inPhase;
  StreamSubscription<SyncProgress>? _syncSubscription;
  String _status = 'Not started';
  List<String> _tracks = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Authenticate with Spotify
      final spotifyApi = await spotifyLogin();

      // Create InPhase instance
      final inPhase = await InPhase.create(
        spotifyApi: spotifyApi,
        rekordboxDbPath: '/path/to/rekordbox/db', // Or null if not needed
      );

      setState(() {
        _inPhase = inPhase;
        _status = 'Ready';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _startSync({List<String>? playlistIds}) {
    if (_inPhase == null) return;

    _syncSubscription = _inPhase!.syncPlaylists(playlistIds: playlistIds).listen(
      (progress) {
        setState(() {
          switch (progress) {
            case SyncProgressStarted():
              _status = 'Starting sync...';
              _tracks.clear();
            case SyncProgressPlaylistStarted(:final playlistName):
              _status = 'Syncing: $playlistName';
            case SyncProgressTrackProcessed(:final trackName, :final artistNames, :final matched):
              final trackInfo = '${artistNames.join(', ')} - $trackName';
              if (matched) {
                _tracks.add('✓ $trackInfo');
              } else {
                _tracks.add('✗ $trackInfo (not found)');
              }
            case SyncProgressPlaylistCompleted(:final report):
              _status = 'Completed playlist: ${report.tracks.length} tracks';
            case SyncProgressCompleted(:final report):
              _status = 'Sync complete! ${report.playlistReports.length} playlists synced';
            case SyncProgressError(:final message):
              _status = 'Error: $message';
          }
        });
      },
      onError: (error) {
        setState(() {
          _status = 'Error: $error';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sync Playlists')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Status: $_status'),
          ),
          ElevatedButton(
            onPressed: _inPhase == null ? null : () => _startSync(),
            child: Text('Start Sync'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_tracks[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _inPhase?.dispose();
    super.dispose();
  }
}
```

**Example: Using crawl functionality**

```dart
Future<void> runCrawl() async {
  final inPhase = await InPhase.create(
    spotifyApi: await spotifyLogin(),
  );

  await for (final progress in inPhase.crawl()) {
    switch (progress) {
      case CrawlProgressJobStarted(:final jobName):
        print('Starting job: $jobName');
      case CrawlProgressJobCompleted(:final report):
        print('Job completed: ${report.trackEntries.length} tracks');
      case CrawlProgressCompleted(:final report):
        print('Crawl complete! ${report.jobReports.length} jobs');
      case CrawlProgressError(:final message):
        print('Error: $message');
    }
  }

  await inPhase.dispose();
}
```

**Example: Searching Rekordbox**

```dart
Future<void> searchTracks() async {
  final inPhase = await InPhase.create(
    spotifyApi: await spotifyLogin(),
    rekordboxDbPath: '/path/to/db',
  );

  final results = await inPhase.search('deep house', limit: 10);

  for (final result in results) {
    print('${result.artist} - ${result.title} (${result.trackId})');
  }

  await inPhase.dispose();
}
```

### 3.5.5 Step-by-Step Implementation Plan

#### Step 1: Create API Class Structure

**Action:** Create `lib/src/api/in_phase.dart` with the `InPhase` class skeleton.

**Tasks:**
- [ ] Define progress event classes (`SyncProgress`, `CrawlProgress`)
- [ ] Define result classes (`SearchResult`)
- [ ] Create `InPhase` class with private constructor
- [ ] Add `create()` factory method
- [ ] Add `dispose()` method
- [ ] Add `_checkDisposed()` helper

#### Step 2: Extract Business Logic from Commands

**Action:** Move business logic from command classes into `InPhase` methods.

**Tasks:**
- [ ] Extract sync logic from `SyncCommand.run()` to `InPhase.syncPlaylists()`
- [ ] Extract crawl logic from `CrawlCommand.run()` to `InPhase.crawl()`
- [ ] Extract search logic from `SearchCommand.run()` to `InPhase.search()`
- [ ] Convert logging statements to progress events
- [ ] Ensure all methods return structured data (not formatted strings)

#### Step 3: Refactor Commands to Use InPhase

**Action:** Update command classes to create `InPhase` instance and delegate to it.

**Example (`lib/src/cli/commands/sync_command.dart`):**

```dart
import 'package:args/command_runner.dart';
import 'package:in_phase/src/api/in_phase.dart';
import 'package:in_phase/src/cli/cli_dependencies.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';

class SyncCommand extends Command<int> {
  SyncCommand();

  @override
  final String name = 'sync';

  @override
  final String description = 'Syncs playlists on Spotify with Rekordbox.';

  @override
  Future<int> run() async {
    return withCliDependencies((deps) async {
      // Create InPhase instance
      final inPhase = await InPhase.create(
        spotifyApi: await spotifyLogin(),
        rekordboxDbPath: null, // CLI handles this via rekorddart
      );

      try {
        // Parse playlist IDs from args if provided
        final playlistIds = argResults!.rest.isNotEmpty
            ? argResults!.rest
            : null;

        // Subscribe to progress stream and log to console
        await for (final progress in inPhase.syncPlaylists(
          playlistIds: playlistIds,
        )) {
          switch (progress) {
            case SyncProgressStarted():
              log.info('Starting sync...');
            case SyncProgressPlaylistStarted(:final playlistName):
              log.info('[${green(playlistName)}] Syncing playlist...');
            case SyncProgressTrackProcessed(:final trackName, :final artistNames, :final matched):
              if (matched) {
                log.info('  ✓ ${artistNames.join(', ')} - $trackName');
              } else {
                log.info('  ✗ ${artistNames.join(', ')} - $trackName (not found)');
              }
            case SyncProgressPlaylistCompleted(:final report):
              log.info('  Completed: ${report.tracks.length} tracks');
            case SyncProgressCompleted(:final report):
              log.info('✅ Sync complete!');
              log.info('Report: ${report.playlistReports.length} playlists synced');
            case SyncProgressError(:final message):
              log.error('❌ Error: $message');
              return ExitCode.software.code;
          }
        }

        return ExitCode.success.code;
      } finally {
        await inPhase.dispose();
      }
    });
  }
}
```

#### Step 4: Export Public API

**Action:** Create export file for external consumption.

**File:** `lib/in_phase_api.dart`

```dart
/// Public API for consuming InPhase functionality in external applications
library in_phase_api;

export 'src/api/in_phase.dart';
export 'src/entities/entities.dart';
export 'src/spotify/types.dart';
export 'src/spotify/spotify.dart' show spotifyLogin;
```

#### Step 5: Update Documentation

**Action:** Document the public API surface.

**Add to README or create API docs:**
- Usage examples
- Method documentation
- Progress event documentation
- Error handling guide

### 3.5.6 Implementation Checklist

**Phase 1: Create InPhase API Class**

- [ ] Create `lib/src/api/in_phase.dart` file
- [ ] Define progress event classes (`SyncProgress`, `CrawlProgress`) using sealed classes
- [ ] Define result classes (`SearchResult`)
- [ ] Create `InPhase` class with private constructor
- [ ] Add `create()` factory method for initialization
- [ ] Add `dispose()` method for cleanup
- [ ] Add `_checkDisposed()` and `_checkRekordboxAvailable()` helper methods

**Phase 2: Extract Business Logic**

- [ ] Extract sync logic from `SyncCommand.run()` to `InPhase.syncPlaylists()`
- [ ] Extract crawl logic from `CrawlCommand.run()` to `InPhase.crawl()`
- [ ] Extract search logic from `SearchCommand.run()` to `InPhase.search()`
- [ ] Convert logging statements to progress events (yield instead of log)
- [ ] Ensure all methods return structured data (not formatted strings)
- [ ] Add config getter/setter methods (`getSyncConfig`, `saveSyncConfig`, etc.)

**Phase 3: Refactor Commands**

- [ ] Update `SyncCommand` to create `InPhase` instance and delegate to it
- [ ] Update `CrawlCommand` to create `InPhase` instance and delegate to it
- [ ] Update `SearchCommand` to create `InPhase` instance and delegate to it
- [ ] Update `LoginCommand` if needed (or keep as-is, GUI handles OAuth separately)
- [ ] Test CLI still works correctly with refactored commands

**Phase 4: Export Public API**

- [ ] Create `lib/in_phase_api.dart` root export file
- [ ] Export `InPhase` class and related types
- [ ] Export `spotifyLogin` function for authentication
- [ ] Export entity types (`SyncConfig`, `CrawlConfig`, etc.)
- [ ] Document public API surface with examples

**Phase 5: Testing**

- [ ] Test `InPhase` class in isolation
- [ ] Test CLI still works with refactored commands
- [ ] Create example Flutter app that consumes the API
- [ ] Verify progress streams work correctly
- [ ] Test error handling and edge cases
- [ ] Verify resource cleanup (dispose works correctly)

### 3.5.7 Key Design Decisions

1. **Single Class API**: One `InPhase` class encapsulates all functionality - simpler than multiple services
2. **Stream-based Progress**: Use Dart streams for real-time progress updates, enabling reactive UI updates
3. **Sealed Classes for Events**: Use Dart 3 sealed classes for type-safe progress events with pattern matching
4. **Factory Pattern**: `InPhase.create()` factory method handles all initialization complexity
5. **Resource Management**: Single `dispose()` method cleans up all resources (databases, connections)
6. **Backward Compatibility**: Refactor commands to use `InPhase`, maintaining CLI functionality
7. **Type Safety**: Keep everything in Dart, no JSON serialization needed for internal API

### 3.5.8 Benefits of Single-Class API Approach

- ✅ **Simple API Surface**: One class to learn, one instance to manage
- ✅ **Encapsulated State**: Authentication, databases, connections all managed internally
- ✅ **Easy Initialization**: Single `create()` method handles all setup
- ✅ **Clear Ownership**: One instance owns all resources, easy to dispose
- ✅ **Separation of Concerns**: Business logic separated from presentation (CLI/GUI)
- ✅ **Reusability**: Same `InPhase` class used by CLI and GUI
- ✅ **Testability**: Can test `InPhase` independently of CLI/GUI
- ✅ **Type Safety**: No serialization overhead, compile-time type checking
- ✅ **Real-time Updates**: Stream-based progress enables reactive UIs
- ✅ **Incremental Migration**: Can refactor one command at a time

---

## 4. Work Breakdown

### 4.1 Phase 1: API Layer Extraction (High Priority)

**Estimated Effort:** 2-3 days

**Tasks:**

1. Create `lib/src/api/in_phase.dart` with `InPhase` class structure
2. Define progress event classes (`SyncProgress`, `CrawlProgress`)
3. Define result classes (`SearchResult`)
4. Extract sync logic from `SyncCommand` to `InPhase.syncPlaylists()` with progress streams
5. Extract crawl logic from `CrawlCommand` to `InPhase.crawl()` with progress streams
6. Extract search logic from `SearchCommand` to `InPhase.search()`
7. Add config management methods (`getSyncConfig`, `saveSyncConfig`, etc.)
8. Refactor commands to use `InPhase` class (maintain CLI compatibility)
9. Create `lib/in_phase_api.dart` export file

**Benefits:**

- Enables GUI to reuse same business logic via single `InPhase` class
- Makes testing easier - test one class instead of multiple services
- Separates concerns - business logic in `InPhase`, presentation in CLI/GUI
- Simple API surface - one class to learn and use

### 4.2 Phase 2: Flutter GUI Foundation (High Priority)

**Estimated Effort:** 3-4 days

**Tasks:**

1. Create Flutter app structure
2. Set up state management (Riverpod recommended)
3. Create navigation structure
4. Implement authentication screen with OAuth flow
5. Create main dashboard/home screen
6. Set up theming and UI components

**Dependencies:** Phase 1 complete

### 4.3 Phase 3: Core Features (Medium Priority)

**Estimated Effort:** 5-7 days

**Tasks:**

1. **Sync UI**

   - Playlist selection/configuration
   - Progress indicator with real-time updates
   - Results display (matches, missing tracks)
   - Report viewer

2. **Crawl UI**

   - Job configuration editor
   - Job execution with progress
   - Results display
   - Report viewer

3. **Search UI**
   - Search interface
   - Results list
   - Track detail view

**Dependencies:** Phase 1 & 2 complete

### 4.4 Phase 4: Configuration Management (Medium Priority)

**Estimated Effort:** 4-5 days

**Tasks:**

1. Sync config editor (forms for patterns, folders, options)
2. Crawl config editor (job editor with source management)
3. Template variable preview
4. Config validation and error display

**Dependencies:** Phase 1 & 2 complete

### 4.5 Phase 5: Polish & Advanced Features (Low Priority)

**Estimated Effort:** 3-4 days

**Tasks:**

1. Settings screen
2. Cache management UI
3. Report history viewer
4. Error handling and user feedback
5. Keyboard shortcuts
6. Dark mode support

**Dependencies:** Phases 1-4 complete

### 4.6 Total Estimated Effort

**With LLM assistance:** 17-23 days
**Human-only:** 30-40 days

**Note:** These estimates assume:

- LLM handles ~60-70% of boilerplate and straightforward code
- Human handles architecture decisions, complex integrations, testing, edge cases
- Iterative development with feedback loops

---

## 5. Technology Stack Recommendation

### 5.1 Recommended Stack: **Dart/Flutter** ⭐

**Rationale:**

1. **Codebase Consistency**

   - Already using Dart
   - Can share code between CLI and GUI
   - Same language, same ecosystem

2. **LLM Capabilities**

   - Composer 1 has strong Flutter/Dart experience
   - Large training corpus for Flutter
   - Excellent tooling support

3. **Cross-Platform**

   - Single codebase for macOS, Windows, Linux
   - Native performance
   - Good desktop support (Flutter 3.0+)

4. **Ecosystem**

   - Rich widget library
   - Strong state management options (Riverpod, Provider, Bloc)
   - Good file system and native integration support

5. **Development Experience**
   - Hot reload for rapid iteration
   - Excellent debugging tools
   - Good documentation

**Recommended Packages:**

- **State Management**: `riverpod` or `flutter_riverpod`
- **Navigation**: `go_router` or `auto_route`
- **HTTP/API**: `http` (already using `spotify` package)
- **OAuth**: `url_launcher` + custom callback handling
- **File Picker**: `file_picker`
- **YAML**: `yaml` (already in dependencies)
- **Markdown**: `flutter_markdown` (for reports)
- **Icons**: `flutter_svg` or Material Icons

### 5.2 Alternative: TypeScript/Electron

**Pros:**

- Web technologies (HTML/CSS/JS) - very familiar to LLMs
- Large ecosystem
- Easy to build and deploy

**Cons:**

- ❌ Different language from codebase
- ❌ Larger bundle size
- ❌ More complex build process
- ❌ Performance overhead
- ❌ Would need to call Dart CLI or rewrite logic

**Verdict:** Not recommended unless web deployment is a priority.

### 5.3 Alternative: Rust + Tauri

**Pros:**

- ✅ Excellent performance
- ✅ Small bundle size
- ✅ Can use web frontend (HTML/CSS/JS)
- ✅ Good security model

**Cons:**

- ❌ Different language from codebase
- ❌ Less LLM training data for Rust GUI frameworks
- ❌ Would need to call Dart CLI or rewrite logic
- ❌ More complex FFI if integrating with Dart code

**Verdict:** Overkill for this use case. Only consider if performance is critical or you want to learn Rust.

---

## 6. Architecture Proposal

### 6.1 Proposed Structure

```
lib/
  src/
    api/                # NEW: Public API surface
      in_phase.dart     # Main InPhase class

    cli/                # EXISTING: CLI commands (refactored to use InPhase)
      commands/
        ...

    gui/                # NEW: Flutter GUI (separate app, consumes InPhase API)
      main.dart
      app.dart
      screens/
        login_screen.dart
        dashboard_screen.dart
        sync_screen.dart
        crawl_screen.dart
        search_screen.dart
        config_screen.dart
      widgets/
        progress_indicator.dart
        playlist_list.dart
        track_list.dart
        ...
      providers/        # State management
        in_phase_provider.dart  # Provides InPhase instance

    # Existing modules remain unchanged
    spotify/
    database/
    entities/
    ...

  in_phase_api.dart     # NEW: Public API export (for external apps)
```

### 6.2 API Layer Design

**Key Principles:**

1. **Single class API** - `InPhase` class encapsulates all functionality
2. **Methods return data, not formatted strings** - Structured return types
3. **Methods emit progress via streams** - Real-time updates for long operations
4. **Testable in isolation** - Can test `InPhase` without CLI/GUI
5. **Resource management** - Single `dispose()` method cleans up everything

**Example API Surface:**

```dart
class InPhase {
  /// Factory method to create instance
  static Future<InPhase> create({
    required SpotifyApi spotifyApi,
    String? rekordboxDbPath,
  });

  /// Syncs playlists, emitting progress events
  Stream<SyncProgress> syncPlaylists({
    List<String>? playlistIds,
  });

  /// Crawls Spotify for new tracks
  Stream<CrawlProgress> crawl({
    List<String>? jobNames,
    DateTime? startDate,
    DateTime? endDate,
    bool dryRun = false,
  });

  /// Searches Rekordbox library
  Future<List<SearchResult>> search(String query, {int limit = 20});

  /// Gets sync configuration
  Future<SyncConfig> getSyncConfig();

  /// Saves sync configuration
  Future<void> saveSyncConfig(SyncConfig config);

  /// Disposes of all resources
  Future<void> dispose();
}
```

### 6.3 GUI Layer Design

**Key Principles:**

1. **Screens are thin** - delegate to providers/services
2. **Providers manage state** - use Riverpod StateNotifier
3. **Widgets are reusable** - extract common UI patterns
4. **Progress is stream-based** - use StreamBuilder for real-time updates

**Example Screen Structure:**

```dart
class SyncScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Sync Playlists')),
      body: Column(
        children: [
          // Playlist selection
          PlaylistSelector(),

          // Progress indicator
          if (syncState.isRunning)
            StreamBuilder<SyncProgress>(
              stream: syncState.progressStream,
              builder: (context, snapshot) {
                return ProgressIndicator(data: snapshot.data);
              },
            ),

          // Results
          if (syncState.completed)
            SyncResultsView(report: syncState.report),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(syncProvider.notifier).startSync(),
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## 7. Implementation Strategy

### 7.1 Incremental Approach

**Phase 1: Extract InPhase API (Week 1)**

- Create `InPhase` class with all methods
- Refactor commands to use `InPhase` instance
- Maintain CLI functionality
- Add progress streams for long operations

**Phase 2: Basic GUI (Week 2)**

- Flutter app skeleton
- Create `InPhase` instance on startup
- Authentication screen
- Dashboard with navigation

**Phase 3: Core Features (Weeks 3-4)**

- Sync UI (uses `InPhase.syncPlaylists()`)
- Crawl UI (uses `InPhase.crawl()`)
- Search UI (uses `InPhase.search()`)

**Phase 4: Configuration (Week 5)**

- Config editors (use `InPhase.getSyncConfig()`, `saveSyncConfig()`, etc.)
- Validation

**Phase 5: Polish (Week 6)**

- Error handling
- Settings
- Reports viewer

### 7.2 LLM-Human Collaboration Model

**LLM Responsibilities:**

- Generate boilerplate code
- Implement straightforward widgets
- Write service layer methods (following patterns)
- Create UI components from specifications
- Handle common Flutter patterns

**Human Responsibilities:**

- Architecture decisions
- Complex integrations (OAuth, file system)
- Testing and debugging
- Edge case handling
- Performance optimization
- User experience decisions

**Workflow:**

1. Human defines interface/API
2. LLM implements following patterns
3. Human reviews and tests
4. Iterate based on feedback

---

## 8. Risks and Mitigations

### 8.1 Technical Risks

**Risk: OAuth flow complexity**

- **Mitigation**: Use proven Flutter OAuth packages, test thoroughly

**Risk: Long-running operations blocking UI**

- **Mitigation**: Use isolates for heavy computation, streams for progress

**Risk: State management complexity**

- **Mitigation**: Use established patterns (Riverpod), start simple

**Risk: Configuration file corruption**

- **Mitigation**: Validate before saving, backup before writes

### 8.2 Project Risks

**Risk: Scope creep**

- **Mitigation**: Focus on MVP first, defer advanced features

**Risk: LLM limitations**

- **Mitigation**: Human reviews all code, handles complex parts

**Risk: Breaking CLI functionality**

- **Mitigation**: Refactor incrementally, maintain tests

---

## 9. Success Criteria

### 9.1 MVP (Minimum Viable Product)

✅ **Must Have:**

- Spotify authentication
- View and sync playlists
- View sync results
- Basic configuration editing

### 9.2 Full Feature Set

✅ **Should Have:**

- Crawl job management
- Search functionality
- Progress indicators
- Report viewing
- Error handling

### 9.3 Nice to Have

✅ **Could Have:**

- Report history
- Cache management UI
- Advanced configuration options
- Keyboard shortcuts
- Dark mode

---

## 10. Conclusion

### 10.1 Feasibility: **HIGH** ✅

Building a GUI for InPhase with LLM assistance is **highly feasible**. The codebase is well-structured, the required changes are clear, and Flutter/Dart provides an excellent platform that aligns with both the existing codebase and LLM capabilities.

### 10.2 Key Success Factors

1. **Incremental refactoring** - Extract services first, then build GUI
2. **Maintain CLI** - Don't break existing functionality
3. **LLM-Human collaboration** - Leverage LLM for boilerplate, human for architecture
4. **Focus on MVP** - Get core features working first

### 10.3 Recommended Next Steps

1. **Create `InPhase` API class** - Extract business logic into single class, this is the foundation
2. **Refactor CLI commands** - Update commands to use `InPhase` instance, maintain compatibility
3. **Create Flutter app skeleton** - Get basic structure in place
4. **Implement authentication** - Critical path item (use `spotifyLogin` then `InPhase.create()`)
5. **Build sync UI first** - Most important feature (use `InPhase.syncPlaylists()`)
6. **Iterate based on feedback** - Refine as you go

### 10.4 Estimated Timeline

**With LLM assistance:** 4-6 weeks for MVP, 8-10 weeks for full feature set
**Human-only:** 8-10 weeks for MVP, 15-20 weeks for full feature set

---

## Appendix A: Command Analysis

### Commands Requiring API Extraction

| Command         | Complexity | Priority | Notes                                             |
| --------------- | ---------- | -------- | ------------------------------------------------- |
| `login`         | Low        | High     | Simple OAuth, needs GUI adaptation                |
| `sync`          | High       | High     | 400+ lines, complex logic, needs progress streams |
| `crawl`         | High       | High     | 700+ lines, complex logic, needs progress streams |
| `search`        | Medium     | Medium   | Interactive CLI, needs GUI adaptation             |
| `cues sync`     | Medium     | Low      | Less critical, can defer                          |
| `config reveal` | Low        | Low      | Simple file operation                             |

### InPhase API Method Priority

1. **`syncPlaylists()`** - Most important feature, extract from `SyncCommand`
2. **`crawl()`** - Second most important, extract from `CrawlCommand`
3. **`search()`** - Useful but less critical, extract from `SearchCommand`
4. **`getSyncConfig()` / `saveSyncConfig()`** - Needed for config editing
5. **`getCrawlConfig()` / `saveCrawlConfig()`** - Needed for crawl config editing
6. **`getPlaylists()`** - Helper method for playlist selection UI

---

## Appendix B: Flutter Package Recommendations

### Core Packages

```yaml
dependencies:
  flutter_riverpod: ^2.0.0 # State management
  go_router: ^13.0.0 # Navigation
  url_launcher: ^6.0.0 # OAuth browser
  file_picker: ^6.0.0 # File selection
  flutter_markdown: ^0.6.0 # Report viewing
  intl: ^0.20.2 # Date formatting (already in deps)
  yaml: ^3.1.3 # Config parsing (already in deps)
```

### UI Packages (Optional)

```yaml
dependencies:
  flutter_svg: ^2.0.0 # SVG icons
  shimmer: ^3.0.0 # Loading animations
  flutter_animate: ^4.0.0 # Animations
```

---

_Document generated: 2025-01-27_
_Analysis by: Composer 1 (Cursor AI)_
