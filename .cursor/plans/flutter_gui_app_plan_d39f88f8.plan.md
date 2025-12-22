---
name: Flutter GUI App Plan
overview: Comprehensive plan for building a Flutter desktop GUI application for in_phase, including project structure, API integration, state management with Riverpod, navigation with Auto Route, and all core features.
todos:
  - id: prerequisite-inphase-api
    content: Create InPhase API class in in_phase package with deferred authentication support, progress streams, and exported types
    status: completed
  - id: prerequisite-export-types
    content: Create lib/in_phase_api.dart export file with all public types (SyncProgress, CrawlProgress, reports, configs)
    status: completed
  - id: prerequisite-restore-session
    content: Add tryRestoreSpotifySession() function to in_phase package - checks cached credentials without triggering OAuth
    status: completed
  - id: setup-project
    content: Create Flutter project with `flutter create --platforms=macos,windows,linux in_phase_app`, init git, add all dependencies
    status: completed
  - id: setup-desktop-window
    content: Configure window_manager for minimum size (800x600), title, and desktop-specific settings
    status: completed
  - id: setup-build-yaml
    content: Create build.yaml with riverpod_generator, auto_route_generator, freezed, json_serializable configuration
    status: completed
  - id: setup-theme
    content: Create app_theme.dart (Material 3, light/dark), app_colors.dart, and app_constants.dart with all layout/timing constants
    status: completed
  - id: setup-router
    content: Configure Auto Route with all routes including SplashRoute, LoginRoute, DashboardRoute, and feature routes
    status: completed
  - id: platform-macos-urlscheme
    content: Configure macOS Info.plist with CFBundleURLTypes for inphase:// URL scheme
    status: completed
  - id: platform-windows-urlscheme
    content: Configure Windows protocol handler registration using win32_registry for inphase:// scheme
    status: completed
  - id: platform-linux-urlscheme
    content: Configure Linux .desktop file with MimeType for inphase:// URL scheme
    status: completed
  - id: oauth-utils
    content: Create oauth_utils.dart with guiOAuthCallback() using app_links package for URL handling
    status: completed
  - id: inphase-provider
    content: Create InPhase provider with keepAlive, Rekordbox path from SharedPreferences, deferred auth support
    status: completed
  - id: auth-provider
    content: Create Auth sealed state class and AuthNotifier with login/logout/checkAuthStatus methods
    status: completed
  - id: auth-guard
    content: Create AutoRouteGuard that checks authProvider state and redirects to login
    status: completed
  - id: splash-screen
    content: Create SplashScreen that checks auth status and redirects to login or dashboard
    status: completed
  - id: login-screen
    content: Create LoginScreen with Spotify login button, loading state, error handling
    status: completed
  - id: onboarding-rekordbox
    content: Create first-time setup flow for Rekordbox database path selection with validation
    status: completed
  - id: dashboard-screen
    content: Build dashboard with feature cards grid, quick stats, recent activity, navigation
    status: completed
  - id: dashboard-providers
    content: Create dashboard providers for stats (last sync, playlist count, crawl jobs)
    status: completed
  - id: sync-state-models
    content: Create SyncState sealed class (Idle, Running, Completed, Error) and form state
    status: completed
  - id: sync-providers
    content: Create SyncNotifier with startSync, cancelSync, stream subscription handling
    status: completed
  - id: sync-screen
    content: Build sync screen with playlist selector, start button, progress indicator
    status: completed
  - id: sync-progress-widget
    content: Create real-time progress widget showing current playlist, track matches
    status: completed
  - id: sync-results-screen
    content: Create results screen with SyncReport viewer, track lists by status
    status: completed
  - id: crawl-state-models
    content: Create CrawlState sealed class and job selection state
    status: completed
  - id: crawl-providers
    content: Create CrawlNotifier with startCrawl, cancelCrawl, job selection
    status: completed
  - id: crawl-screen
    content: Build crawl screen with job list, checkboxes, run selected/all buttons
    status: completed
  - id: crawl-job-editor
    content: Create job editor screen for creating/editing crawl jobs with source management
    status: pending
  - id: crawl-results-screen
    content: Create results screen with CrawlReport viewer, track lists by job
    status: completed
  - id: search-providers
    content: Create search query StateProvider, debounced search FutureProvider with 500ms delay
    status: completed
  - id: search-screen
    content: Build search screen with search bar, results list, empty state
    status: completed
  - id: track-detail-card
    content: Create track detail card showing BPM, key, cue info, file path
    status: completed
  - id: config-providers
    content: Create config providers for loading/saving SyncConfig and CrawlConfig
    status: completed
  - id: sync-config-editor
    content: Build sync config editor with pattern list, folder options, Camelot key filter
    status: pending
  - id: crawl-config-editor
    content: Build crawl config editor with job list, add/edit/delete jobs
    status: pending
  - id: config-form-validation
    content: Implement form validation with error display and save confirmation
    status: pending
  - id: settings-screen
    content: Build settings screen with sections for Rekordbox, cache, theme, about
    status: completed
  - id: rekordbox-path-selector
    content: Create Rekordbox path selector with file picker and validation
    status: completed
  - id: cache-management
    content: Create cache management UI with size display and clear buttons with confirmation
    status: completed
  - id: theme-selector
    content: Create theme selector (system/light/dark) with ThemeMode provider
    status: completed
  - id: shared-widgets
    content: Create LoadingIndicator, AppErrorWidget, EmptyState, ProgressBar reusable widgets
    status: completed
  - id: confirmation-dialogs
    content: Create reusable confirmation dialog for destructive actions (logout, clear cache)
    status: completed
  - id: error-handler-provider
    content: Create global ErrorHandler provider with user-friendly message mapping
    status: completed
  - id: snackbar-service
    content: Create SnackBar service for showing success/error/info messages
    status: completed
  - id: keyboard-shortcuts
    content: Implement keyboard shortcuts (Cmd+S sync, Cmd+F search, Cmd+, settings, etc.)
    status: completed
  - id: test-mocks
    content: Create MockInPhase class implementing InPhase interface for testing
    status: pending
  - id: test-providers
    content: Write unit tests for auth, sync, crawl, search, config providers
    status: pending
  - id: test-widgets
    content: Write widget tests for screens with provider overrides
    status: pending
  - id: test-integration
    content: Write integration tests for auth flow and main user journeys
    status: pending
  - id: build-app-icons
    content: Create app icons for macOS (1024x1024), Windows (.ico), Linux (multiple sizes)
    status: pending
  - id: build-macos
    content: Configure macOS build with bundle ID, entitlements, code signing, DMG packaging
    status: pending
  - id: build-windows
    content: Configure Windows build with MSIX/EXE installer packaging
    status: pending
  - id: build-linux
    content: Configure Linux build with .deb and AppImage packaging
    status: pending
  - id: build-scripts
    content: Create build scripts for each platform in scripts/ directory
    status: pending
  - id: todo-1766020505381-lrk3q74go
    content: This is a test-todo. Ignore it.
    status: in_progress
---

# Flutter GUI Application Plan for InPhase

## What is InPhase?

**InPhase** is a music library management tool that bridges Spotify and Rekordbox, enabling DJs and music enthusiasts to:

- **Sync playlists** from Spotify to Rekordbox for use in DJ software
- **Discover new music** by crawling Spotify playlists, artists, labels, and YouTube channels
- **Search and manage** tracks in their Rekordbox library
- **Configure automated workflows** for music discovery and playlist management

Currently, InPhase is a **command-line tool** written in Dart. This plan describes building a **Flutter desktop GUI application** that provides a user-friendly graphical interface for all InPhase functionality.

## What is This GUI App?

The **InPhase GUI App** (`in_phase_app`) is a Flutter desktop application (macOS, Windows, Linux) that provides:

- **Visual interface** for all InPhase operations
- **Real-time progress tracking** for sync and crawl operations
- **Configuration editors** for managing sync and crawl jobs
- **Dashboard** with quick stats and recent activity
- **Search interface** for browsing Rekordbox library
- **Settings management** for Rekordbox database path and preferences

The app consumes the `in_phase` package via a clean API layer, uses Riverpod for state management, Auto Route for navigation, and follows Flutter desktop best practices.

## Feature Breakdown

### 1. Authentication

- **Spotify OAuth login** via browser/webview
- **Authentication state management** (logged in/out)
- **Credential caching** and automatic refresh
- **Logout functionality**

### 2. Dashboard

- **Feature cards** for quick access to main features
- **Quick statistics** (last sync time, playlist count, etc.)
- **Recent activity** display
- **Quick action buttons** (sync, crawl, search)

### 3. Sync Feature

- **Playlist selection** (manual or via config patterns)
- **Real-time progress tracking** with stream-based updates
- **Track matching display** (matched/unmatched tracks)
- **Sync report viewer** with detailed results
- **Error handling** and retry mechanisms

### 4. Crawl Feature

- **Job management** (list, create, edit, delete crawl jobs)
- **Job execution** with progress tracking per job
- **Source management** (playlists, artists, labels, YouTube channels)
- **Template configuration** for playlist naming
- **Crawl report viewer** with track discovery results

### 5. Search Feature

- **Debounced search** for Rekordbox library
- **Track results display** with details (BPM, key, cues, etc.)
- **Track detail view** with full information
- **Fast search** with real-time results

### 6. Configuration Management

- **Sync config editor**:
  - Playlist pattern matching
  - Folder organization
  - Camelot key filtering
  - Advanced options
- **Crawl config editor**:
  - Job creation and editing
  - Source management (add/remove sources)
  - Template variable configuration
  - Date range settings
- **Form validation** and preview
- **YAML file management** (load/save)

### 7. Settings

- **Rekordbox database path** selector
- **Cache management** (view/clear cache)
- **Theme selector** (light/dark mode)
- **About section** with app info

### 8. Reports

- **Sync report history** viewer
- **Crawl report history** viewer
- **Markdown report rendering**
- **Export functionality** (future enhancement)

## Overview

This plan outlines the development of the Flutter desktop GUI application (`in_phase_app`) that provides a graphical interface for the InPhase music library management tool. The app will consume the `in_phase` package via a clean API layer, use Riverpod for state management, Auto Route for navigation, and follow Flutter desktop best practices.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│      Flutter GUI App (in_phase_app)     │
│  - Riverpod State Management            │
│  - Auto Route Navigation                │
│  - Material Design UI                   │
└─────────────────┬───────────────────────┘
                  │
                  │ Consumes API
                  │
┌─────────────────▼───────────────────────┐
│      in_phase Package API Layer         │
│  - InPhase class (single entry point)   │
│  - Progress streams (Sync/Crawl)        │
│  - Configuration management             │
└─────────────────┬───────────────────────┘
                  │
                  │ Uses
                  │
┌─────────────────▼───────────────────────┐
│      Existing in_phase Core Logic       │
│  - Spotify API integration              │
│  - Rekordbox database access            │
│  - Sync/Crawl/Search operations         │
└─────────────────────────────────────────┘
```

## Project Structure

```
in_phase_app/
├── lib/
│   ├── main.dart                              # App entry point with window config
│   ├── app.dart                               # MaterialApp.router setup
│   │
│   ├── core/
│   │   ├── router/
│   │   │   ├── app_router.dart               # Auto Route configuration
│   │   │   ├── app_router.gr.dart            # Generated routes
│   │   │   └── guards/
│   │   │       └── auth_guard.dart           # Authentication guard
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart                # Material 3 theme configuration
│   │   │   └── app_colors.dart               # Color definitions (if needed)
│   │   │
│   │   ├── constants/
│   │   │   └── app_constants.dart            # App-wide constants
│   │   │
│   │   ├── providers/
│   │   │   ├── in_phase_provider.dart        # InPhase API instance provider
│   │   │   └── error_handler_provider.dart   # Global error handling
│   │   │
│   │   ├── services/
│   │   │   └── snackbar_service.dart         # SnackBar notifications
│   │   │
│   │   ├── widgets/
│   │   │   └── keyboard_shortcuts_wrapper.dart # Desktop keyboard shortcuts
│   │   │
│   │   └── utils/
│   │       ├── oauth_utils.dart              # OAuth callback (app_links)
│   │       ├── windows_protocol_handler.dart # Windows URL scheme registration
│   │       └── file_utils.dart               # File picker helpers
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── auth_state.dart       # Sealed auth state class
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── auth_providers.dart   # Auth notifier with login/logout
│   │   │       ├── screens/
│   │   │       │   ├── splash_screen.dart    # Initial loading/routing
│   │   │       │   └── login_screen.dart     # Spotify login UI
│   │   │       └── widgets/
│   │   │           └── login_button.dart
│   │   │
│   │   ├── onboarding/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── onboarding_screen.dart # First-time setup wizard
│   │   │
│   │   ├── dashboard/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── dashboard_providers.dart # Stats and recent activity
│   │   │       ├── screens/
│   │   │       │   └── dashboard_screen.dart
│   │   │       └── widgets/
│   │   │           ├── feature_card.dart
│   │   │           ├── quick_stats.dart
│   │   │           └── recent_activity.dart
│   │   │
│   │   ├── sync/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── sync_state.dart       # Sealed sync state class
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── sync_providers.dart   # Sync notifier with cancellation
│   │   │       ├── screens/
│   │   │       │   ├── sync_screen.dart      # Playlist selection & control
│   │   │       │   └── sync_results_screen.dart # Report viewer
│   │   │       └── widgets/
│   │   │           ├── playlist_selector.dart
│   │   │           ├── sync_progress_indicator.dart
│   │   │           ├── track_match_list.dart
│   │   │           └── sync_report_viewer.dart
│   │   │
│   │   ├── crawl/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── crawl_state.dart      # Sealed crawl state class
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── crawl_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── crawl_screen.dart     # Job list & execution
│   │   │       │   ├── crawl_job_editor_screen.dart
│   │   │       │   └── crawl_results_screen.dart
│   │   │       └── widgets/
│   │   │           ├── job_list.dart
│   │   │           ├── job_card.dart
│   │   │           ├── crawl_progress_indicator.dart
│   │   │           ├── source_editor.dart
│   │   │           └── crawl_report_viewer.dart
│   │   │
│   │   ├── search/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── search_providers.dart # Debounced search
│   │   │       ├── screens/
│   │   │       │   └── search_screen.dart
│   │   │       └── widgets/
│   │   │           ├── search_text_field.dart
│   │   │           ├── track_result_list.dart
│   │   │           └── track_detail_card.dart
│   │   │
│   │   ├── config/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       ├── sync_config_form_state.dart
│   │   │   │       └── crawl_config_form_state.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── config_providers.dart
│   │   │       ├── screens/
│   │   │       │   ├── config_screen.dart    # Tab view for configs
│   │   │       │   ├── sync_config_editor_screen.dart
│   │   │       │   └── crawl_config_editor_screen.dart
│   │   │       └── widgets/
│   │   │           ├── pattern_editor.dart
│   │   │           ├── pattern_list.dart
│   │   │           ├── folder_selector.dart
│   │   │           ├── camelot_key_selector.dart
│   │   │           ├── job_editor_form.dart
│   │   │           └── source_list_editor.dart
│   │   │
│   │   └── settings/
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── settings_providers.dart # Theme, path, cache
│   │           ├── screens/
│   │           │   └── settings_screen.dart
│   │           └── widgets/
│   │               ├── rekordbox_path_selector.dart
│   │               ├── cache_management.dart
│   │               ├── theme_selector.dart
│   │               └── about_section.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── loading_indicator.dart
│       │   ├── app_error_widget.dart
│       │   ├── empty_state.dart
│       │   ├── progress_bar.dart
│       │   └── confirmation_dialog.dart
│       └── extensions/
│           └── build_context_extensions.dart
│
├── test/
│   ├── mocks/
│   │   └── mock_in_phase.dart               # Mock/Fake InPhase for tests
│   ├── helpers/
│   │   └── test_helpers.dart                # Test widget builders
│   ├── features/
│   │   ├── sync/
│   │   │   └── presentation/
│   │   │       └── providers/
│   │   │           └── sync_providers_test.dart
│   │   ├── search/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── search_screen_test.dart
│   │   └── ...
│   └── core/
│       └── providers/
│           └── error_handler_test.dart
│
├── integration_test/
│   ├── app_test.dart
│   ├── auth_flow_test.dart
│   └── sync_flow_test.dart
│
├── macos/
│   └── Runner/
│       ├── Info.plist                       # URL scheme configuration
│       └── Release.entitlements             # Network entitlements
│
├── windows/
│   └── runner/
│       └── main.cpp
│
├── linux/
│   └── inphase.desktop                      # Desktop entry (for packaging)
│
├── scripts/
│   ├── build_macos.sh
│   ├── build_windows.bat
│   └── build_linux.sh
│
├── pubspec.yaml
├── build.yaml                               # Code generation config
├── analysis_options.yaml
└── README.md
```

## Platform-Specific Configuration

### Desktop Window Configuration

Configure `window_manager` in `main.dart` for proper desktop behavior:

```dart
// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure desktop window
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      title: 'InPhase',
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: InPhaseApp()));
}
```

### macOS URL Scheme Configuration

**File:** `macos/Runner/Info.plist`

Add inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.inphase.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>inphase</string>
    </array>
  </dict>
</array>
```

Also ensure network access in `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

### Windows URL Scheme Configuration

**File:** `lib/core/utils/windows_protocol_handler.dart`

```dart
import 'dart:io';
import 'package:win32_registry/win32_registry.dart';

/// Registers the inphase:// URL scheme on Windows
/// Call this once on first app launch
Future<void> registerWindowsProtocolHandler() async {
  if (!Platform.isWindows) return;

  final appPath = Platform.resolvedExecutable;
  const scheme = 'inphase';

  try {
    final protocolKey = Registry.currentUser.createKey(
      'Software\\Classes\\$scheme',
    );
    protocolKey.createValue(const RegistryValue(
      '',
      RegistryValueType.string,
      'URL:InPhase Protocol',
    ));
    protocolKey.createValue(const RegistryValue(
      'URL Protocol',
      RegistryValueType.string,
      '',
    ));

    final commandKey = protocolKey.createKey('shell\\open\\command');
    commandKey.createValue(RegistryValue(
      '',
      RegistryValueType.string,
      '"$appPath" "%1"',
    ));
  } catch (e) {
    // Log but don't fail - user might not have permissions
    print('Failed to register URL scheme: $e');
  }
}
```

### Linux URL Scheme Configuration

**File:** `linux/inphase.desktop` (create in your Linux packaging)

```ini
[Desktop Entry]
Name=InPhase
Comment=Music library management tool
Exec=/usr/bin/inphase %u
Icon=inphase
Type=Application
Categories=Audio;Music;
MimeType=x-scheme-handler/inphase;
StartupNotify=true
```

Register during installation:

```bash
xdg-mime default inphase.desktop x-scheme-handler/inphase
```

## App Constants Specification

**File:** `lib/core/constants/app_constants.dart`

```dart
import 'package:flutter/material.dart';

/// Application-wide constants
abstract final class AppConstants {
  // App Info
  static const String appName = 'InPhase';
  static const String appVersion = '1.0.0';
  static const String appBundleId = 'com.inphase.app';
  
  // Window Sizing
  static const Size defaultWindowSize = Size(1200, 800);
  static const Size minimumWindowSize = Size(800, 600);
  
  // Layout
  static const double sidebarWidth = 240.0;
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Timing
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration animationDurationSlow = Duration(milliseconds: 400);
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration oauthTimeout = Duration(minutes: 5);
  static const Duration refreshCooldown = Duration(seconds: 2);
  
  // OAuth
  static const String spotifyRedirectScheme = 'inphase';
  static const String spotifyRedirectUri = 'inphase://auth-callback';
  
  // Storage Keys
  static const String keyRekordboxPath = 'rekordbox_db_path';
  static const String keyThemeMode = 'theme_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyWindowBounds = 'window_bounds';
  
  // Limits
  static const int maxSearchResults = 100;
  static const int maxRecentReports = 20;
  static const int maxPlaylistsToShow = 500;
  
  // Keyboard Shortcuts (for documentation)
  static const Map<String, String> keyboardShortcuts = {
    'Cmd/Ctrl + S': 'Start sync',
    'Cmd/Ctrl + F': 'Focus search',
    'Cmd/Ctrl + ,': 'Open settings',
    'Cmd/Ctrl + R': 'Refresh current view',
    'Cmd/Ctrl + 1': 'Go to Dashboard',
    'Cmd/Ctrl + 2': 'Go to Sync',
    'Cmd/Ctrl + 3': 'Go to Crawl',
    'Cmd/Ctrl + 4': 'Go to Search',
    'Escape': 'Cancel/close dialog',
  };
}
```

## Theme Configuration

**File:** `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';

/// Application theme configuration using Material 3
class AppTheme {
  static const _seedColor = Color(0xFF6750A4); // Deep purple
  
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.compact, // Better for desktop
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      
      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Lists
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
  
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.compact,
      
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
```

## Development Workflow Guidelines

### Code Analysis and Tooling

- **Dart MCP**: Use the Dart MCP (Model Context Protocol) server wherever possible for:
  - Code analysis and type checking
  - Running tests and build commands
  - Static analysis and linter checks
  - Any other available MCP functionality
- **Fallback**: When MCP is unavailable or insufficient, fall back to:
  - Static code analysis using `dart analyze`
  - Linter checks using `dart pub run linter`
  - Manual code review

### Dependency Management

- **Use `dart pub add`**: Always use `dart pub add <package>` to add dependencies instead of manually editing `pubspec.yaml`
- **Example**: `dart pub add flutter_riverpod` instead of manually adding to dependencies section
- **Dev dependencies**: Use `dart pub add --dev <package>` for dev dependencies

### Version Control

- **Git initialization**: Initialize git repository at project creation
- **Conventional commits**: Use conventional commit format for all commits:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `chore:` for maintenance tasks (dependencies, build config, etc.)
  - `refactor:` for code refactoring
  - `docs:` for documentation changes
  - `test:` for adding or updating tests
  - `style:` for formatting changes
- **Milestone commits**: Make commits at logical milestone points:
  - After completing each phase or major feature
  - After fixing critical bugs
  - After significant refactoring
  - Example: `feat: add sync feature with progress tracking`

### Code Style: Sealed Classes and Switch Expressions

- **Never use `.when()`**: Always use Dart 3 switch expressions instead
- **Use sealed classes**: For all state classes, progress events, result types, and discriminated unions
- **Benefits**: Exhaustiveness checking, compile-time safety, better IDE support
- **Reference**: See "Coding Standards: Sealed Classes and Switch Expressions" in Technical Considerations section

## Phase 1: Project Setup and Foundation

### 1.1 Create Flutter Project

**Tasks:**

- Initialize git repository: `git init`
- Create new Flutter project: `flutter create --platforms=macos,windows,linux in_phase_app`
- Add dependencies using `dart pub add`:
  - `dart pub add flutter_riverpod`
  - `dart pub add riverpod_annotation`
  - `dart pub add auto_route`
  - `dart pub add auto_route_annotations`
  - `dart pub add url_launcher`
  - `dart pub add file_picker`
  - `dart pub add flutter_markdown`
  - `dart pub add intl`
  - `dart pub add freezed_annotation`
  - `dart pub add json_annotation`
  - `dart pub add shared_preferences`
  - Add `in_phase` path dependency manually (edit `pubspec.yaml`):
    ```yaml
    dependencies:
      in_phase:
        path: ../in_phase
    ```

- Add dev dependencies using `dart pub add --dev`:
  - `dart pub add --dev build_runner`
  - `dart pub add --dev riverpod_generator`
  - `dart pub add --dev auto_route_generator`
  - `dart pub add --dev json_serializable`
  - `dart pub add --dev freezed`
- Run `dart pub get` to fetch dependencies
- Use Dart MCP to analyze project structure and verify setup

**Files to Create:**

- `pubspec.yaml` (generated by Flutter, then modified)
- `analysis_options.yaml` (copy from in_phase)
- `.gitignore` (Flutter standard)
- `.git/` (initialized by git init)

**Commit:** `chore: initialize Flutter project with dependencies`

### 1.2 Setup Code Generation

**Tasks:**

- Configure `build.yaml` for code generation
- Create initial router file (`lib/core/router/app_router.dart`)
- Create initial providers file structure
- Setup build scripts in `README.md`
- Use Dart MCP to verify code generation setup
- Run `dart run build_runner build --delete-conflicting-outputs` to test generation

**Files to Create:**

- `build.yaml`
- `lib/core/router/app_router.dart` (skeleton)

**Commit:** `chore: setup code generation for Riverpod and Auto Route`

### 1.3 Theme and Constants

**Tasks:**

- Define Material Design 3 theme
- Create color scheme (light/dark mode support)
- Define typography
- Create app-wide constants (sizes, durations, etc.)
- Use Dart MCP to analyze theme implementation and check for issues

**Files to Create:**

- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/constants/app_constants.dart`

**Commit:** `feat: add theme configuration and app constants`

## Phase 2: API Integration Layer

### 2.1 InPhase API Provider

**Tasks:**

- Create Riverpod provider for `InPhase` instance
- **Important**: InPhase API should allow creating instance first, then authenticating later
- Handle initialization (Rekordbox DB path, but NOT Spotify auth - that happens separately)
- Manage lifecycle (dispose on app exit)
- Handle errors (auth failures, DB connection issues)

**Files to Create:**

- `lib/core/providers/in_phase_provider.dart`

**Implementation Notes:**

- Use `AsyncNotifierProvider` for async initialization
- Store Rekordbox DB path in app preferences
- **Create InPhase instance without authentication** - authentication happens via separate provider/method
- Handle credential refresh automatically
- Provide clear error messages for common failures
- Use Dart MCP to analyze provider implementation and verify type safety

**Proposed InPhase API Changes:**

The `InPhase` API should be modified to:

1. Allow creating instance without authentication: `InPhase.create(rekordboxDbPath: ...)` - SpotifyApi is optional
2. Add `authenticate(SpotifyApi spotifyApi)` method to authenticate after creation
3. Operations throw `StateError` if called without authentication (except config operations)
4. Add `bool get isAuthenticated` getter to check auth state

**Files to Create:**

- `lib/core/providers/in_phase_provider.dart`

**Commit:** `feat: add InPhase API provider with deferred authentication support`

### 2.2 Authentication State Management

**Tasks:**

- Create sealed class for authentication state
- Create provider that manages authentication state
- Link authentication state to InPhase instance authentication
- Use authentication state to control UI visibility

**Files to Create:**

- `lib/features/auth/data/models/auth_state.dart` - Sealed class for auth state
- `lib/features/auth/presentation/providers/auth_providers.dart` - Auth state provider

**Authentication State (Sealed Class):**

```dart
// lib/features/auth/data/models/auth_state.dart
sealed class AuthState {
  const AuthState();
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateAuthenticating extends AuthState {
  const AuthStateAuthenticating();
}

class AuthStateAuthenticated extends AuthState {
  final SpotifyApi spotifyApi;
  final User user;
  
  const AuthStateAuthenticated({
    required this.spotifyApi,
    required this.user,
  });
}

class AuthStateError extends AuthState {
  final String message;
  final Object? error;
  
  const AuthStateError({
    required this.message,
    this.error,
  });
}
```

**Auth Provider:**

```dart
// lib/features/auth/presentation/providers/auth_providers.dart
import 'package:in_phase/in_phase_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/auth_state.dart';
import '../../../../core/providers/in_phase_provider.dart';
import '../../../../core/utils/oauth_utils.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true) // Keep auth state alive across navigation
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthStateUnauthenticated();
  
  /// Initiates the full OAuth login flow (opens browser)
  /// 
  /// This will open a browser window for the user to authenticate with Spotify.
  /// Use [checkAuthStatus] first to see if we can restore a cached session.
  Future<void> login() async {
    state = const AuthStateAuthenticating();
    
    try {
      // This opens browser for OAuth - only call when user explicitly wants to login
      final spotifyApi = await spotifyLogin(
        redirectAndGetResponseUri: guiOAuthCallback,
      );
      
      await _completeAuthentication(spotifyApi);
    } catch (e, stack) {
      state = AuthStateError(
        message: _mapLoginError(e),
        error: e,
      );
    }
  }
  
  /// Logs out the current user
  Future<void> logout() async {
    final currentState = state;
    if (currentState case AuthStateAuthenticated()) {
      // Clear credentials from storage
      await spotifyLogout();
      
      // Clear authentication from InPhase instance
      final inPhase = ref.read(inPhaseProvider).valueOrNull;
      if (inPhase != null) {
        await inPhase.logout();
      }
    }
    
    state = const AuthStateUnauthenticated();
  }
  
  /// Attempts to restore a session from cached credentials
  /// 
  /// Unlike [login], this does NOT open a browser or prompt for authentication.
  /// It simply checks if we have valid cached credentials and uses them.
  /// Returns silently to [AuthStateUnauthenticated] if no cached session exists.
  Future<void> checkAuthStatus() async {
    // Try to restore session from cached credentials
    // This does NOT trigger OAuth flow - returns null if no cached credentials
    final spotifyApi = await tryRestoreSpotifySession();
    
    if (spotifyApi == null) {
      // No cached credentials, user needs to login
      state = const AuthStateUnauthenticated();
      return;
    }
    
    // We have cached credentials, complete authentication
    try {
      await _completeAuthentication(spotifyApi);
    } catch (e) {
      // Cached credentials might be expired/invalid
      await spotifyLogout(); // Clear invalid credentials
      state = const AuthStateUnauthenticated();
    }
  }
  
  /// Shared logic to complete authentication after obtaining SpotifyApi
  Future<void> _completeAuthentication(SpotifyApi spotifyApi) async {
    // Fetch user info to verify credentials work
    final user = await spotifyApi.me.get();
    
    // Authenticate InPhase instance
    final inPhase = ref.read(inPhaseProvider).valueOrNull;
    if (inPhase != null) {
      await inPhase.authenticate(spotifyApi);
    }
    
    state = AuthStateAuthenticated(
      spotifyApi: spotifyApi,
      user: user,
    );
  }
  
  String _mapLoginError(Object error) {
    return switch (error) {
      TimeoutException() => 'Login timed out. Please try again.',
      Exception() when error.toString().contains('cancelled') => 
        'Login was cancelled.',
      Exception() when error.toString().contains('browser') => 
        'Failed to open browser. Please check your default browser settings.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
```

**Required Addition to in_phase Package:**

The `in_phase` package needs a new function that only tries cached credentials without triggering OAuth:

```dart
// Add to lib/src/spotify/api.dart

/// Attempts to restore a Spotify session from cached credentials.
/// 
/// Unlike [spotifyLogin], this does NOT open a browser or trigger OAuth flow.
/// Returns the authenticated [SpotifyApi] if valid cached credentials exist,
/// or `null` if no cached credentials are available.
/// 
/// Throws [AuthorizationException] if cached credentials exist but are invalid/expired
/// and cannot be refreshed.
Future<SpotifyApi?> tryRestoreSpotifySession() async {
  return await _attemptCachedCredentialsLogin();
}

// The existing private function already does what we need:
Future<SpotifyApi?> _attemptCachedCredentialsLogin() async {
  final env = Zonable.fromZone<Env>();
  final credentialsDataResult = await _credentialsEntry.readOrNull();

  final _SavedClientCredentials credentialsData;

  switch (credentialsDataResult) {
    case DoosErr(:final error):
      throw Exception('Failed to read credentials: $error');
    case DoosOk(value: null):
      return null; // No cached credentials
    case DoosOk(value: final credentialsData_?):
      credentialsData = credentialsData_;
  }

  final credentials = credentialsData.toSpotifyApiCredentials(
    clientId: env.spotifyClientId,
    clientSecret: env.spotifyClientSecret,
  );
  final api = SpotifyApi(
    credentials,
    onCredentialsRefreshed: _writeCredentials,
  );
  await _writeCredentials(await api.getCredentials());

  return api;
}
```

**Key Distinction:**

| Function | Opens Browser? | Use Case |

|----------|----------------|----------|

| `spotifyLogin()` | Yes (if no cache) | User clicks "Login" button |

| `tryRestoreSpotifySession()` | Never | App startup, checking auth status |

| `spotifyLogout()` | No | User clicks "Logout" button |

### 2.3 OAuth Authentication Flow

**Tasks:**

- Implement custom URL scheme handler (e.g., `inphase://auth-callback`)
- Create OAuth screen with webview or browser launcher
- Handle redirect callback and extract authorization code
- Integrate with `spotifyLogin` function from `in_phase` package
- Call auth provider's `login()` method on successful authentication

**Files to Create:**

- `lib/features/auth/presentation/screens/login_screen.dart` - Login screen UI
- `lib/features/auth/presentation/widgets/oauth_webview.dart` - Optional webview widget (if using embedded webview instead of system browser)
- `lib/core/utils/oauth_utils.dart` - **Critical**: Contains `guiOAuthCallback()` function that handles GUI OAuth flow

**Platform Configuration:**

- **macOS**: Update `macos/Runner/Info.plist` with URL scheme
- **Windows**: Update `windows/runner/main.cpp` for URL handling
- **Linux**: Configure desktop entry file

**Implementation Notes:**

- **Critical**: Pass a custom `redirectAndGetResponseUri` function to `spotifyLogin()` - never call it without arguments (that would use CLI terminal method)
- Create a custom function that:

  1. Opens browser/webview with the auth URL using `url_launcher`
  2. Sets up URL scheme listener (using `uni_links` or platform channels)
  3. Waits for callback URL matching the redirect scheme (`inphase://auth-callback`)
  4. Extracts and returns the callback URL string
  5. Handles cancellation/timeout gracefully

- Use `uni_links` or platform channels to handle callback
- Show loading state during authentication
- Handle cancellation gracefully
- Store credentials securely (handled by `in_phase` package)
- Use Dart MCP to test OAuth flow and verify platform-specific configurations

**Complete OAuth Implementation:**

**File:** `lib/core/utils/oauth_utils.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Handles OAuth callback for GUI authentication
/// 
/// This function is passed to `spotifyLogin()` from the in_phase package
/// to handle the OAuth flow in a GUI context instead of CLI.
Future<String> guiOAuthCallback(Uri authUri) async {
  // Open system browser with auth URL
  final launched = await launchUrl(
    authUri,
    mode: LaunchMode.externalApplication,
  );
  
  if (!launched) {
    throw Exception('Failed to open browser for authentication');
  }
  
  // Set up deep link listener using app_links
  final appLinks = AppLinks();
  final completer = Completer<String>();
  StreamSubscription<Uri>? linkSubscription;
  Timer? timeoutTimer;
  
  void cleanup() {
    linkSubscription?.cancel();
    timeoutTimer?.cancel();
  }
  
  // Listen for incoming deep links
  linkSubscription = appLinks.uriLinkStream.listen(
    (Uri uri) {
      final uriString = uri.toString();
      if (uriString.startsWith(AppConstants.spotifyRedirectUri) ||
          uriString.startsWith('${AppConstants.spotifyRedirectScheme}://')) {
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(uriString);
        }
      }
    },
    onError: (Object error) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    },
  );
  
  // Also check for initial link (in case app was launched from OAuth redirect)
  appLinks.getInitialLink().then((Uri? initialUri) {
    if (initialUri != null) {
      final uriString = initialUri.toString();
      if (uriString.startsWith(AppConstants.spotifyRedirectScheme)) {
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(uriString);
        }
      }
    }
  });
  
  // Timeout after configured duration
  timeoutTimer = Timer(AppConstants.oauthTimeout, () {
    cleanup();
    if (!completer.isCompleted) {
      completer.completeError(
        TimeoutException(
          'OAuth authentication timed out after ${AppConstants.oauthTimeout.inMinutes} minutes',
          AppConstants.oauthTimeout,
        ),
      );
    }
  });
  
  return completer.future;
}

/// Checks if the app was launched from an OAuth callback URL
/// Call this early in app initialization
Future<String?> checkInitialOAuthLink() async {
  final appLinks = AppLinks();
  final initialUri = await appLinks.getInitialLink();
  
  if (initialUri != null) {
    final uriString = initialUri.toString();
    if (uriString.startsWith(AppConstants.spotifyRedirectScheme)) {
      return uriString;
    }
  }
  return null;
}
```

**Registering Windows URL Scheme on First Launch:**

```dart
// In main.dart or splash screen
Future<void> _initializePlatform() async {
  if (Platform.isWindows) {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
    
    if (isFirstLaunch) {
      await registerWindowsProtocolHandler();
      await prefs.setBool(AppConstants.keyFirstLaunch, false);
    }
  }
}
```

**Commit:** `feat: implement OAuth authentication flow with platform-specific URL handling`

### 2.4 UI State Based on Authentication

**Tasks:**

- Update UI to show/hide features based on authentication state
- Disable buttons/actions when not authenticated
- Show login prompt when authentication required
- Handle authentication errors gracefully

**Implementation:**

```dart
// Example: Dashboard screen checks auth state
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final inPhaseAsync = ref.watch(inPhaseProvider);
    
    return switch (authState) {
      AuthStateUnauthenticated() => 
        Center(
          child: Column(
            children: [
              Text('Please log in to continue'),
              ElevatedButton(
                onPressed: () => context.pushRoute(const LoginRoute()),
                child: Text('Login'),
              ),
            ],
          ),
        ),
      AuthStateAuthenticating() => 
        const Center(child: CircularProgressIndicator()),
      AuthStateError(:final message) => 
        Center(
          child: Column(
            children: [
              Text('Error: $message'),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).login(),
                child: Text('Retry Login'),
              ),
            ],
          ),
        ),
      AuthStateAuthenticated(:final user) => 
        Scaffold(
          appBar: AppBar(title: Text('Welcome, ${user.displayName}')),
          body: DashboardContent(),
        ),
    };
  }
}

// Example: Sync button checks auth before enabling
ElevatedButton(
  onPressed: switch (ref.watch(authProvider)) {
    AuthStateAuthenticated() => () => _startSync(),
    _ => null, // Disabled when not authenticated
  },
  child: Text('Start Sync'),
)
```

**Commit:** `feat: add UI state management based on authentication status`

## Phase 3: Navigation Setup

### 3.1 Auto Route Configuration

**Tasks:**

- Define all routes in `app_router.dart`
- Create route guards for authentication
- Setup initial route logic based on authentication state (login vs dashboard)
- Configure route transitions

**Files to Create:**

- `lib/core/router/app_router.dart` (complete)
- `lib/core/router/guards/auth_guard.dart`

**Route Structure:**

```dart
- /login (LoginScreen) - public (redirects to dashboard if already authenticated)
- /dashboard (DashboardScreen) - protected (requires authentication)
- /sync (SyncScreen) - protected (requires authentication)
- /sync/results/:reportId (SyncResultsScreen) - protected
- /crawl (CrawlScreen) - protected (requires authentication)
- /crawl/job/:jobName/edit (CrawlJobEditorScreen) - protected
- /crawl/results/:reportId (CrawlResultsScreen) - protected
- /search (SearchScreen) - protected (requires authentication)
- /config (ConfigScreen) - protected (config can be viewed without auth, but editing may require auth)
- /config/sync (SyncConfigEditorScreen) - protected
- /config/crawl (CrawlConfigEditorScreen) - protected
- /settings (SettingsScreen) - protected
```

**Initial Route Logic:**

```dart
// In app_router.dart or main.dart
@override
List<AutoRoute> get routes => [
  AutoRoute(
    page: SplashScreen,
    initial: true,
    path: '/',
  ),
  AutoRoute(page: LoginPage, path: '/login'),
  AutoRoute(
    page: DashboardPage,
    path: '/dashboard',
    guards: [AuthGuard],
  ),
  // ... other routes
];

// SplashScreen checks auth state and redirects
class SplashScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Check auth status on app start
    ref.listen(authProvider, (previous, next) {
      if (next case AuthStateAuthenticated()) {
        context.router.replace(const DashboardRoute());
      } else if (next case AuthStateUnauthenticated()) {
        context.router.replace(const LoginRoute());
      }
    });
    
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
    
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

### 3.2 Navigation Integration

**Tasks:**

- Integrate router with MaterialApp
- Create navigation service/provider (optional, for programmatic navigation)
- Setup deep linking support
- Test navigation flow
- Use Dart MCP to verify route generation and navigation setup

**Files to Modify:**

- `lib/app.dart`
- `lib/main.dart`

**Commit:** `feat: integrate Auto Route navigation with route guards`

## Phase 3.5: Onboarding and First-Time Setup

### 3.5.1 Splash Screen

The splash screen handles initial app state and routing decisions.

**File:** `lib/features/auth/presentation/screens/splash_screen.dart`

```dart
@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Check for first launch / onboarding needed
    final prefs = await SharedPreferences.getInstance();
    final rekordboxPath = prefs.getString(AppConstants.keyRekordboxPath);
    final isFirstLaunch = prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
    
    // Register Windows URL scheme on first launch
    if (Platform.isWindows && isFirstLaunch) {
      await registerWindowsProtocolHandler();
      await prefs.setBool(AppConstants.keyFirstLaunch, false);
    }
    
    // Check if onboarding needed (no Rekordbox path set)
    if (rekordboxPath == null || rekordboxPath.isEmpty) {
      if (mounted) {
        context.router.replace(const OnboardingRoute());
      }
      return;
    }
    
    // Check authentication status
    await ref.read(authProvider.notifier).checkAuthStatus();
    
    // Listen for auth state changes
    final authState = ref.read(authProvider);
    
    if (mounted) {
      switch (authState) {
        case AuthStateAuthenticated():
          context.router.replace(const DashboardRoute());
        case _:
          context.router.replace(const LoginRoute());
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.album,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

### 3.5.2 Onboarding Flow

For first-time users who need to configure Rekordbox path.

**File:** `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

```dart
@RoutePage()
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  String? _rekordboxPath;
  bool _isValidating = false;
  String? _validationError;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
              ),
              const SizedBox(height: 48),
              
              // Step content
              Expanded(
                child: switch (_currentStep) {
                  0 => _buildWelcomeStep(),
                  1 => _buildRekordboxStep(),
                  2 => _buildReadyStep(),
                  _ => const SizedBox(),
                },
              ),
              
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  ElevatedButton(
                    onPressed: _canProceed() ? _nextStep : null,
                    child: Text(_currentStep == 2 ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.album,
          size: 100,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Welcome to InPhase',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Bridge your Spotify library with Rekordbox.\n'
          'Sync playlists, discover new music, and manage your DJ library.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
  
  Widget _buildRekordboxStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.folder_open, size: 64),
        const SizedBox(height: 24),
        Text(
          'Locate Rekordbox Database',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'InPhase needs access to your Rekordbox database to sync tracks.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        if (_rekordboxPath != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Database found'),
              subtitle: Text(_rekordboxPath!, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (_validationError != null) ...[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error, 
                color: Theme.of(context).colorScheme.error),
              title: Text(_validationError!),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        ElevatedButton.icon(
          onPressed: _isValidating ? null : _selectRekordboxPath,
          icon: _isValidating 
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.folder_open),
          label: Text(_rekordboxPath == null ? 'Select Database' : 'Change'),
        ),
        
        const SizedBox(height: 24),
        TextButton(
          onPressed: _showHelp,
          child: const Text('Where is my Rekordbox database?'),
        ),
      ],
    );
  }
  
  Widget _buildReadyStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 100, color: Colors.green),
        const SizedBox(height: 32),
        Text(
          'You\'re all set!',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        const Text(
          'Next, you\'ll log in with your Spotify account\n'
          'to start syncing your playlists.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  bool _canProceed() {
    return switch (_currentStep) {
      0 => true,
      1 => _rekordboxPath != null && _validationError == null,
      2 => true,
      _ => false,
    };
  }
  
  Future<void> _selectRekordboxPath() async {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });
    
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Rekordbox Database Folder',
      );
      
      if (result != null) {
        // Validate the path
        final isValid = await _validateRekordboxPath(result);
        
        if (isValid) {
          setState(() => _rekordboxPath = result);
          
          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyRekordboxPath, result);
        } else {
          setState(() {
            _validationError = 'This doesn\'t appear to be a valid Rekordbox database folder.';
          });
        }
      }
    } finally {
      setState(() => _isValidating = false);
    }
  }
  
  Future<bool> _validateRekordboxPath(String path) async {
    // Check if the path contains expected Rekordbox database files
    final dir = Directory(path);
    if (!await dir.exists()) return false;
    
    // Look for master.db or similar Rekordbox files
    final files = await dir.list().toList();
    return files.any((f) => 
      f.path.endsWith('master.db') || 
      f.path.contains('rekordbox')
    );
  }
  
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Complete onboarding, go to login
      context.router.replace(const LoginRoute());
    }
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finding Rekordbox Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The Rekordbox database is typically located at:'),
            const SizedBox(height: 16),
            if (Platform.isMacOS)
              const SelectableText(
                '~/Library/Pioneer/rekordbox/',
              ),
            if (Platform.isWindows)
              const SelectableText(
                'C:\\Users\\<username>\\AppData\\Roaming\\Pioneer\\rekordbox\\',
              ),
            if (Platform.isLinux)
              const SelectableText(
                '~/.rekordbox/',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
```

**Commit:** `feat: add onboarding flow with Rekordbox path setup`

## Phase 4: Core Features Implementation

### 4.1 Dashboard Screen

**Tasks:**

- Create dashboard layout with feature cards
- Display quick stats (last sync time, playlist count, etc.)
- Show recent activity
- Provide quick actions (sync, crawl, search)

**Files to Create:**

- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- `lib/features/dashboard/presentation/widgets/feature_card.dart`
- `lib/features/dashboard/presentation/widgets/quick_stats.dart`

**UI Components:**

- Grid layout with feature cards
- Statistics cards (sync count, crawl jobs, etc.)
- Recent reports list
- Quick action buttons

**Commit:** `feat: add dashboard screen with feature cards and quick stats`

### 4.2 Sync Feature

**Tasks:**

- Create sync screen with playlist selection
- Implement progress indicator using stream subscription
- Display real-time track matching results
- Show sync report after completion
- Handle errors gracefully

**Files to Create:**

- `lib/features/sync/presentation/screens/sync_screen.dart`
- `lib/features/sync/presentation/providers/sync_providers.dart`
- `lib/features/sync/presentation/widgets/playlist_selector.dart`
- `lib/features/sync/presentation/widgets/sync_progress_indicator.dart`
- `lib/features/sync/presentation/widgets/track_match_list.dart`
- `lib/features/sync/presentation/screens/sync_results_screen.dart`
- `lib/features/sync/presentation/widgets/sync_report_viewer.dart`

**State Management:**

- Use `StreamProvider` for sync progress stream
- Use `AsyncNotifierProvider` for sync state
- **Progress events must be sealed classes**: `SyncProgressStarted`, `SyncProgressPlaylistStarted`, `SyncProgressTrackProcessed`, `SyncProgressCompleted`, `SyncProgressError`
- **State classes must be sealed classes**: `SyncStateIdle`, `SyncStateRunning`, `SyncStateCompleted`, `SyncStateError`
- Use switch expressions (never `.when()`) to handle progress events and state

**UI Flow:**

1. User selects playlists (or uses config patterns)
2. Click "Start Sync" button
3. Show progress indicator with current playlist name
4. Display track matches/unmatched in real-time list
5. Show completion summary with report link
6. Navigate to results screen for detailed report

**Commit:** `feat: implement sync feature with progress tracking and results display`

### 4.3 Crawl Feature

**Tasks:**

- Create crawl screen with job list
- Implement job execution with progress
- Display crawl results
- Create job editor for creating/editing crawl jobs

**Files to Create:**

- `lib/features/crawl/presentation/screens/crawl_screen.dart`
- `lib/features/crawl/presentation/providers/crawl_providers.dart`
- `lib/features/crawl/presentation/widgets/job_list.dart`
- `lib/features/crawl/presentation/widgets/crawl_progress_indicator.dart`
- `lib/features/crawl/presentation/screens/crawl_job_editor_screen.dart`
- `lib/features/crawl/presentation/widgets/source_editor.dart`
- `lib/features/crawl/presentation/screens/crawl_results_screen.dart`
- `lib/features/crawl/presentation/widgets/crawl_report_viewer.dart`

**State Management:**

- Use `StreamProvider` for crawl progress stream
- Use `AsyncNotifierProvider` for crawl state
- Handle progress events: `CrawlProgressJobStarted`, `CrawlProgressJobCompleted`, `CrawlProgressCompleted`, `CrawlProgressError`

**UI Flow:**

1. Display list of crawl jobs from config
2. User selects jobs to run (or runs all)
3. Show progress for each job
4. Display results with track counts
5. Show completion summary
6. Navigate to results screen for detailed report

**Commit:** `feat: implement crawl feature with job management and progress tracking`

### 4.4 Search Feature

**Tasks:**

- Create search screen with search bar
- Implement search with debouncing
- Display search results in list
- Show track details on selection

**Files to Create:**

- `lib/features/search/presentation/screens/search_screen.dart`
- `lib/features/search/presentation/providers/search_providers.dart`
- `lib/features/search/presentation/widgets/search_bar.dart`
- `lib/features/search/presentation/widgets/track_result_list.dart`
- `lib/features/search/presentation/widgets/track_detail_card.dart`

**State Management with Debouncing:**

```dart
// lib/features/search/presentation/providers/search_providers.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:in_phase/in_phase_api.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/in_phase_provider.dart';

part 'search_providers.g.dart';

/// Raw search query - updated immediately on user input
@riverpod
class SearchQueryRaw extends _$SearchQueryRaw {
  @override
  String build() => '';
  
  void update(String query) => state = query;
  
  void clear() => state = '';
}

/// Debounced search query - only updates after user stops typing
/// This is what triggers the actual search
@riverpod
class SearchQueryDebounced extends _$SearchQueryDebounced {
  Timer? _debounceTimer;
  
  @override
  String build() {
    // Listen to raw query changes
    ref.listen(searchQueryRawProvider, (previous, next) {
      _debounceTimer?.cancel();
      
      if (next.isEmpty) {
        // Clear immediately when empty
        state = '';
      } else {
        // Debounce non-empty queries
        _debounceTimer = Timer(AppConstants.searchDebounce, () {
          state = next;
        });
      }
    });
    
    // Cleanup on dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    
    return '';
  }
}

/// Search results - only fetches when debounced query changes
@riverpod
Future<List<SearchResult>> searchResults(SearchResultsRef ref) async {
  final query = ref.watch(searchQueryDebouncedProvider);
  
  if (query.isEmpty) {
    return [];
  }
  
  final inPhase = await ref.watch(inPhaseProvider.future);
  return await inPhase.search(query, limit: AppConstants.maxSearchResults);
}

/// Selected track for detail view
@riverpod
class SelectedTrack extends _$SelectedTrack {
  @override
  SearchResult? build() => null;
  
  void select(SearchResult track) => state = track;
  void clear() => state = null;
}
```

**Search Screen UI:**

```dart
@RoutePage()
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryRawProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final selectedTrack = ref.watch(selectedTrackProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Rekordbox'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search tracks by name, artist, or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(searchQueryRawProvider.notifier).clear();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(searchQueryRawProvider.notifier).update(value);
              },
            ),
          ),
          
          // Results
          Expanded(
            child: switch (resultsAsync) {
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AsyncError(:final error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, 
                         color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Search failed: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(searchResultsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              AsyncData(value: []) when query.isEmpty => const EmptyState(
                icon: Icons.search,
                title: 'Search your Rekordbox library',
                subtitle: 'Enter a track name, artist, or Rekordbox ID',
              ),
              AsyncData(value: []) => const EmptyState(
                icon: Icons.music_off,
                title: 'No tracks found',
                subtitle: 'Try a different search term',
              ),
              AsyncData(:final value) => TrackResultList(
                tracks: value,
                selectedTrack: selectedTrack,
                onTrackTap: (track) {
                  ref.read(selectedTrackProvider.notifier).select(track);
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}
```

**UI Flow:**

1. User types in search bar
2. Raw query updates immediately (for clearing button visibility)
3. Debounced query updates after 500ms of no typing
4. Search results fetch only when debounced query changes
5. Display results in list with loading/error/empty states
6. Show track details on tap

**Commit:** `feat: add search feature with debounced search and results display`

### 4.5 Configuration Management

**Tasks:**

- Create config screen with sync/crawl config tabs
- Implement sync config editor (patterns, folders, Camelot keys)
- Implement crawl config editor (jobs, sources, templates)
- Add form validation
- Preview config changes

**Files to Create:**

- `lib/features/config/presentation/screens/config_screen.dart`
- `lib/features/config/presentation/providers/config_providers.dart`
- `lib/features/config/presentation/screens/sync_config_editor_screen.dart`
- `lib/features/config/presentation/widgets/pattern_editor.dart`
- `lib/features/config/presentation/widgets/folder_selector.dart`
- `lib/features/config/presentation/widgets/camelot_key_selector.dart`
- `lib/features/config/presentation/screens/crawl_config_editor_screen.dart`
- `lib/features/config/presentation/widgets/job_editor_form.dart`
- `lib/features/config/presentation/widgets/source_list_editor.dart`

**State Management:**

- Use `AsyncNotifierProvider` for config loading/saving
- Use `NotifierProvider` for form state
- **Form state should be a sealed class** if it represents multiple states (e.g., `ConfigFormStateIdle`, `ConfigFormStateEditing`, `ConfigFormStateSaving`, `ConfigFormStateError`)
- Validate before saving
- Show preview of changes
- Use switch expressions (never `.when()`) to handle `AsyncValue` and form state

**UI Flow:**

1. Load current config on screen open
2. Display config in editable form
3. User makes changes
4. Validate on save
5. Show success/error message
6. Refresh config display

**Commit:** `feat: add configuration editors for sync and crawl configs`

## Phase 5: Settings and Polish

### 5.1 Settings Screen

**Tasks:**

- Create settings screen
- Add Rekordbox database path selector
- Implement cache management UI
- Add theme selector (light/dark)
- Add about section

**Files to Create:**

- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/providers/settings_providers.dart`
- `lib/features/settings/presentation/widgets/rekordbox_path_selector.dart`
- `lib/features/settings/presentation/widgets/cache_management.dart`
- `lib/features/settings/presentation/widgets/theme_selector.dart`

**Commit:** `feat: add settings screen with Rekordbox path selector and theme management`

### 5.2 Shared Widgets

**Tasks:**

- Create reusable loading indicator
- Create error widget with retry
- Create empty state widget
- Create progress bar component

**Files to Create:**

- `lib/shared/widgets/loading_indicator.dart`
- `lib/shared/widgets/error_widget.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/progress_bar.dart`

### 5.3 Error Handling

**Tasks:**

- Implement global error handler
- Create error display widgets
- Add retry mechanisms
- Show user-friendly error messages
- Use Dart MCP to test error handling scenarios

**Files to Create:**

- `lib/core/providers/error_handler_provider.dart`
- `lib/shared/widgets/error_widget.dart`
- `lib/core/services/snackbar_service.dart`

**Global Error Handler:**

```dart
// lib/core/providers/error_handler_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

part 'error_handler_provider.g.dart';

final _log = Logger('ErrorHandler');

/// Error severity levels
enum ErrorSeverity {
  info,    // Informational, user can dismiss
  warning, // Something went wrong but app can continue
  error,   // Operation failed, user action needed
  fatal,   // Critical error, app may need restart
}

/// User-facing error with message and optional action
class AppError {
  final String message;
  final String? details;
  final ErrorSeverity severity;
  final Object? originalError;
  final StackTrace? stackTrace;
  final VoidCallback? retryAction;
  
  const AppError({
    required this.message,
    this.details,
    this.severity = ErrorSeverity.error,
    this.originalError,
    this.stackTrace,
    this.retryAction,
  });
}

@riverpod
class ErrorHandler extends _$ErrorHandler {
  @override
  AppError? build() => null;
  
  /// Handles an error and returns a user-friendly AppError
  AppError handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    VoidCallback? retryAction,
  }) {
    // Log the error
    _log.severe('Error in $context: $error', error, stackTrace);
    
    // Convert to user-friendly message
    final appError = _mapErrorToAppError(error, stackTrace, retryAction);
    
    // Update state so UI can react
    state = appError;
    
    return appError;
  }
  
  /// Clears the current error
  void clearError() {
    state = null;
  }
  
  AppError _mapErrorToAppError(
    Object error, 
    StackTrace? stackTrace,
    VoidCallback? retryAction,
  ) {
    return switch (error) {
      // Authentication errors
      StateError(:final message) when message.contains('not authenticated') =>
        AppError(
          message: 'Please log in to continue',
          details: 'This action requires Spotify authentication.',
          severity: ErrorSeverity.warning,
          originalError: error,
          stackTrace: stackTrace,
        ),
      
      // Network errors
      SocketException() => AppError(
        message: 'Network connection failed',
        details: 'Please check your internet connection and try again.',
        severity: ErrorSeverity.error,
        originalError: error,
        stackTrace: stackTrace,
        retryAction: retryAction,
      ),
      
      // Timeout errors
      TimeoutException(:final message) => AppError(
        message: 'Operation timed out',
        details: message ?? 'The operation took too long. Please try again.',
        severity: ErrorSeverity.warning,
        originalError: error,
        stackTrace: stackTrace,
        retryAction: retryAction,
      ),
      
      // File system errors
      FileSystemException(:final message) => AppError(
        message: 'File access error',
        details: message,
        severity: ErrorSeverity.error,
        originalError: error,
        stackTrace: stackTrace,
      ),
      
      // Rekordbox database errors
      StateError(:final message) when message.contains('Rekordbox') =>
        AppError(
          message: 'Rekordbox database error',
          details: 'Unable to access Rekordbox database. Please check the path in Settings.',
          severity: ErrorSeverity.error,
          originalError: error,
          stackTrace: stackTrace,
        ),
      
      // Generic error with message
      Exception(:final message) when message != null => AppError(
        message: 'An error occurred',
        details: message.toString(),
        severity: ErrorSeverity.error,
        originalError: error,
        stackTrace: stackTrace,
        retryAction: retryAction,
      ),
      
      // Fallback for unknown errors
      _ => AppError(
        message: 'An unexpected error occurred',
        details: error.toString(),
        severity: ErrorSeverity.error,
        originalError: error,
        stackTrace: stackTrace,
        retryAction: retryAction,
      ),
    };
  }
}

// Extension to get message from exceptions
extension on Exception {
  String? get message {
    final str = toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}
```

**SnackBar Service for Showing Messages:**

```dart
// lib/core/services/snackbar_service.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'snackbar_service.g.dart';

/// Message types for snackbar styling
enum MessageType { success, error, warning, info }

/// Snackbar message to display
class SnackBarMessage {
  final String message;
  final MessageType type;
  final Duration duration;
  final SnackBarAction? action;
  
  const SnackBarMessage({
    required this.message,
    this.type = MessageType.info,
    this.duration = const Duration(seconds: 4),
    this.action,
  });
}

@riverpod
class SnackBarService extends _$SnackBarService {
  @override
  SnackBarMessage? build() => null;
  
  void showSuccess(String message, {SnackBarAction? action}) {
    state = SnackBarMessage(
      message: message,
      type: MessageType.success,
      action: action,
    );
  }
  
  void showError(String message, {VoidCallback? onRetry}) {
    state = SnackBarMessage(
      message: message,
      type: MessageType.error,
      duration: const Duration(seconds: 6),
      action: onRetry != null 
        ? SnackBarAction(label: 'Retry', onPressed: onRetry)
        : null,
    );
  }
  
  void showWarning(String message) {
    state = SnackBarMessage(
      message: message,
      type: MessageType.warning,
    );
  }
  
  void showInfo(String message) {
    state = SnackBarMessage(
      message: message,
      type: MessageType.info,
    );
  }
  
  void clear() {
    state = null;
  }
}
```

**Reusable Error Widget:**

```dart
// lib/shared/widgets/app_error_widget.dart
import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  
  const AppErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Confirmation Dialog for Destructive Actions:**

```dart
// lib/shared/widgets/confirmation_dialog.dart
import 'package:flutter/material.dart';

/// Shows a confirmation dialog and returns true if confirmed
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
            ? TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              )
            : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  
  return result ?? false;
}

// Usage examples:
// await showConfirmationDialog(
//   context: context,
//   title: 'Clear Cache',
//   message: 'This will delete all cached data. Continue?',
//   confirmLabel: 'Clear',
//   isDestructive: true,
// );

// await showConfirmationDialog(
//   context: context,
//   title: 'Log Out',
//   message: 'Are you sure you want to log out?',
//   confirmLabel: 'Log Out',
// );
```

**Commit:** `feat: implement global error handling with user-friendly messages`

### 5.4 UI/UX Polish

**Tasks:**

- Add animations and transitions
- Implement pull-to-refresh where applicable
- Add keyboard shortcuts
- Improve loading states
- Add tooltips and help text
- Implement responsive layouts

### 5.5 Keyboard Shortcuts

Implement desktop keyboard shortcuts for power users.

**File:** `lib/core/widgets/keyboard_shortcuts_wrapper.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import '../constants/app_constants.dart';

/// Wraps the app with keyboard shortcut handling
class KeyboardShortcutsWrapper extends StatelessWidget {
  final Widget child;
  final WidgetRef ref;
  
  const KeyboardShortcutsWrapper({
    super.key,
    required this.child,
    required this.ref,
  });
  
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Navigation shortcuts
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
          () => context.router.navigate(const DashboardRoute()),
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
          () => context.router.navigate(const SyncRoute()),
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true):
          () => context.router.navigate(const CrawlRoute()),
        const SingleActivator(LogicalKeyboardKey.digit4, meta: true):
          () => context.router.navigate(const SearchRoute()),
          
        // For Windows/Linux, use control instead of meta
        const SingleActivator(LogicalKeyboardKey.digit1, control: true):
          () => context.router.navigate(const DashboardRoute()),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true):
          () => context.router.navigate(const SyncRoute()),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true):
          () => context.router.navigate(const CrawlRoute()),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true):
          () => context.router.navigate(const SearchRoute()),
        
        // Action shortcuts
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
          () => _handleStartSync(ref),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
          () => _handleStartSync(ref),
          
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          () => context.router.navigate(const SearchRoute()),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          () => context.router.navigate(const SearchRoute()),
          
        const SingleActivator(LogicalKeyboardKey.comma, meta: true):
          () => context.router.navigate(const SettingsRoute()),
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
          () => context.router.navigate(const SettingsRoute()),
          
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
          () => _handleRefresh(context, ref),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
          () => _handleRefresh(context, ref),
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
  
  void _handleStartSync(WidgetRef ref) {
    final syncState = ref.read(syncNotifierProvider);
    if (syncState case SyncStateIdle()) {
      ref.read(syncNotifierProvider.notifier).startSync();
    }
  }
  
  void _handleRefresh(BuildContext context, WidgetRef ref) {
    // Refresh based on current route
    final currentRoute = context.router.current.name;
    
    switch (currentRoute) {
      case 'DashboardRoute':
        ref.invalidate(dashboardStatsProvider);
      case 'SearchRoute':
        ref.invalidate(searchResultsProvider);
      case 'CrawlRoute':
        ref.invalidate(crawlConfigProvider);
      case 'ConfigRoute':
        ref.invalidate(syncConfigProvider);
        ref.invalidate(crawlConfigProvider);
    }
  }
}
```

**Keyboard Shortcuts Reference (in Settings/Help):**

| Shortcut | Action |

|----------|--------|

| `⌘/Ctrl + 1` | Go to Dashboard |

| `⌘/Ctrl + 2` | Go to Sync |

| `⌘/Ctrl + 3` | Go to Crawl |

| `⌘/Ctrl + 4` | Go to Search |

| `⌘/Ctrl + S` | Start Sync (when on Sync screen) |

| `⌘/Ctrl + F` | Focus Search |

| `⌘/Ctrl + ,` | Open Settings |

| `⌘/Ctrl + R` | Refresh current view |

| `Escape` | Cancel/close dialog |

**Commit:** `feat: add keyboard shortcuts for desktop navigation`

## Phase 6: Testing

### 6.1 Mock InPhase Implementation

Create a mock implementation of InPhase for testing.

**File:** `test/mocks/mock_in_phase.dart`

```dart
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:in_phase/in_phase_api.dart';

/// Mock InPhase for unit testing
class MockInPhase extends Mock implements InPhase {}

/// Fake implementations for testing
class FakeInPhase implements InPhase {
  bool _isAuthenticated = false;
  final _mockPlaylists = <PlaylistSimple>[
    // Add mock playlists
  ];
  
  @override
  bool get isAuthenticated => _isAuthenticated;
  
  @override
  Future<void> authenticate(SpotifyApi spotifyApi) async {
    _isAuthenticated = true;
  }
  
  @override
  Future<void> logout() async {
    _isAuthenticated = false;
  }
  
  @override
  Stream<SyncProgress> syncPlaylists({List<String>? playlistIds}) async* {
    yield const SyncProgressStarted(playlistCount: 1);
    await Future.delayed(const Duration(milliseconds: 100));
    
    yield SyncProgressPlaylistStarted(
      playlistName: 'Test Playlist',
      playlistId: SpotifyPlaylistId('test-id'),
    );
    
    yield SyncProgressTrackProcessed(
      trackEntry: SyncTrackAdded(
        trackId: SpotifyTrackId('track-1'),
        trackName: 'Test Track',
        artistNames: ['Test Artist'],
        rekordboxSongId: RekordboxSongId('rb-1'),
        rekordboxTitle: 'Test Track',
      ),
    );
    
    yield SyncProgressCompleted(
      report: SyncReport(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        playlistReports: [],
      ),
    );
  }
  
  @override
  Stream<CrawlProgress> crawl({
    List<String>? jobNames,
    DateTime? startDate,
    DateTime? endDate,
    bool dryRun = false,
  }) async* {
    yield CrawlProgressJobStarted(jobName: 'Test Job');
    await Future.delayed(const Duration(milliseconds: 100));
    yield CrawlProgressCompleted(
      report: CrawlReport(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        jobReports: [],
      ),
    );
  }
  
  @override
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    return [
      SearchResult(
        trackId: 'rb-1',
        title: 'Test Track',
        artist: 'Test Artist',
        bpm: 128,
        lengthSeconds: 240,
        hotCueCount: 4,
        memoryCueCount: 2,
      ),
    ];
  }
  
  @override
  Future<SyncConfig> getSyncConfig() async {
    return SyncConfig.empty();
  }
  
  @override
  Future<void> saveSyncConfig(SyncConfig config) async {}
  
  @override
  Future<CrawlConfig> getCrawlConfig() async {
    return CrawlConfig.empty();
  }
  
  @override
  Future<void> saveCrawlConfig(CrawlConfig config) async {}
  
  @override
  Future<void> dispose() async {}
}
```

### 6.2 Test Helpers

**File:** `test/helpers/test_helpers.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_phase_app/core/router/app_router.dart';
import '../mocks/mock_in_phase.dart';

/// Creates a testable widget wrapped with providers
Widget buildTestWidget(
  Widget child, {
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: [
      inPhaseProvider.overrideWith((ref) async => FakeInPhase()),
      ...?overrides,
    ],
    child: MaterialApp(home: child),
  );
}

/// Creates a testable widget with router support
Widget buildTestWidgetWithRouter(
  PageRouteInfo initialRoute, {
  List<Override>? overrides,
}) {
  final container = ProviderContainer(
    overrides: [
      inPhaseProvider.overrideWith((ref) async => FakeInPhase()),
      ...?overrides,
    ],
  );
  
  final router = AppRouter(container);
  
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router.config(
        initialRoutes: [initialRoute],
      ),
    ),
  );
}

/// Pumps widget and waits for all animations
extension WidgetTesterExtensions on WidgetTester {
  Future<void> pumpAndSettleAll() async {
    await pumpAndSettle();
    await pump(const Duration(milliseconds: 100));
  }
}
```

### 6.3 Provider Tests

**File:** `test/features/sync/presentation/providers/sync_providers_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:in_phase_app/features/sync/presentation/providers/sync_providers.dart';
import 'package:in_phase_app/features/sync/data/models/sync_state.dart';
import '../../../../mocks/mock_in_phase.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('SyncNotifier', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer(
        overrides: [
          inPhaseProvider.overrideWith((ref) async => FakeInPhase()),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('initial state is SyncStateIdle', () {
      final state = container.read(syncNotifierProvider);
      expect(state, isA<SyncStateIdle>());
    });
    
    test('startSync transitions through states correctly', () async {
      final notifier = container.read(syncNotifierProvider.notifier);
      final states = <SyncState>[];
      
      container.listen(
        syncNotifierProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );
      
      await notifier.startSync();
      
      // Wait for stream to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      expect(states, containsAllInOrder([
        isA<SyncStateIdle>(),
        isA<SyncStateRunning>(),
        isA<SyncStateCompleted>(),
      ]));
    });
    
    test('cancelSync sets state to SyncStateCancelled', () async {
      final notifier = container.read(syncNotifierProvider.notifier);
      
      // Start sync
      notifier.startSync();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Cancel
      notifier.cancelSync();
      await Future.delayed(const Duration(milliseconds: 100));
      
      final state = container.read(syncNotifierProvider);
      expect(state, isA<SyncStateCancelled>());
    });
    
    test('reset returns to SyncStateIdle', () {
      final notifier = container.read(syncNotifierProvider.notifier);
      
      notifier.reset();
      
      expect(container.read(syncNotifierProvider), isA<SyncStateIdle>());
    });
  });
}
```

### 6.4 Widget Tests

**File:** `test/features/search/presentation/screens/search_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_phase_app/features/search/presentation/screens/search_screen.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('SearchScreen', () {
    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();
      
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search tracks by name, artist, or ID...'), findsOneWidget);
    });
    
    testWidgets('shows empty state when no query', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();
      
      expect(find.text('Search your Rekordbox library'), findsOneWidget);
    });
    
    testWidgets('shows results after typing and debounce', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();
      
      // Type in search bar
      await tester.enterText(find.byType(TextField), 'test');
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      
      // Should show results from FakeInPhase
      expect(find.text('Test Track'), findsOneWidget);
    });
    
    testWidgets('clears search when clear button tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();
      
      // Type in search bar
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      
      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      
      // Search field should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });
}
```

### 6.5 Integration Tests

**Tasks:**

- Test complete user flows
- Test authentication flow end-to-end
- Test sync flow from start to completion
- Test navigation between all screens

**Files to Create:**

- `integration_test/app_test.dart`
- `integration_test/auth_flow_test.dart`
- `integration_test/sync_flow_test.dart`

**Commit:** `test: add comprehensive unit, widget, and integration tests`

## Phase 7: Build and Deployment

### 7.1 Build Configuration

**Tasks:**

- Configure app name and version
- Set app icons for all platforms
- Configure app bundle IDs/package names
- Setup code signing (macOS/Windows)

**Files to Modify:**

- `pubspec.yaml`
- Platform-specific config files

### 7.2 Distribution

**Tasks:**

- Create build scripts
- Package for macOS (.dmg)
- Package for Windows (.exe installer)
- Package for Linux (.deb, .AppImage)
- Create release notes
- Use Dart MCP to verify build configurations

**Files to Create:**

- `scripts/build_macos.sh`
- `scripts/build_windows.bat`
- `scripts/build_linux.sh`

**Commit:** `chore: add build scripts for platform-specific distribution`

## Required InPhase Package Changes

**Important**: The `in_phase` package must be modified to expose a clean API for the GUI app. These changes should be implemented in the `in_phase` package **before** building the GUI app.

### Phase 0: Create Public API Export File

**File:** `lib/in_phase_api.dart`

This file exports all public types needed by the GUI app:

```dart
/// Public API for consuming InPhase functionality in external applications
library in_phase_api;

// Main API class
export 'src/api/in_phase.dart';

// Progress events (sealed classes)
export 'src/api/progress/sync_progress.dart';
export 'src/api/progress/crawl_progress.dart';

// Report entities
export 'src/entities/reports/sync_report.dart';
export 'src/entities/reports/crawl_report.dart';

// Configuration entities
export 'src/entities/sync_config.dart';
export 'src/entities/crawl_config.dart';

// Spotify types needed by consumers
export 'src/spotify/types.dart' show SpotifyPlaylistId, SpotifyTrackId, RekordboxSongId;

// Search result type
export 'src/api/search_result.dart';

// Authentication functions
export 'src/spotify/api.dart' show spotifyLogin, spotifyLogout, tryRestoreSpotifySession;

// Re-export spotify User type for auth state
export 'package:spotify/spotify.dart' show User, SpotifyApi, PlaylistSimple;
```

### Types to Create/Export

**Progress Events (already exists as sealed classes in reports):**

The sync_report.dart already has `SyncTrackEntry` as a sealed class. We need to create similar progress event sealed classes:

**File:** `lib/src/api/progress/sync_progress.dart`

```dart
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/spotify/types.dart';

/// Progress events for sync operations
sealed class SyncProgress {
  const SyncProgress();
}

class SyncProgressStarted extends SyncProgress {
  final int playlistCount;
  const SyncProgressStarted({required this.playlistCount});
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
  final SyncTrackEntry trackEntry;
  const SyncProgressTrackProcessed({required this.trackEntry});
}

class SyncProgressPlaylistCompleted extends SyncProgress {
  final SyncPlaylistReport report;
  const SyncProgressPlaylistCompleted({required this.report});
}

class SyncProgressCompleted extends SyncProgress {
  final SyncReport report;
  const SyncProgressCompleted({required this.report});
}

class SyncProgressError extends SyncProgress {
  final String message;
  final Object? error;
  const SyncProgressError({required this.message, this.error});
}
```

**File:** `lib/src/api/progress/crawl_progress.dart`

```dart
import 'package:in_phase/src/entities/entities.dart';

/// Progress events for crawl operations
sealed class CrawlProgress {
  const CrawlProgress();
}

class CrawlProgressStarted extends CrawlProgress {
  final int jobCount;
  const CrawlProgressStarted({required this.jobCount});
}

class CrawlProgressJobStarted extends CrawlProgress {
  final String jobName;
  const CrawlProgressJobStarted({required this.jobName});
}

class CrawlProgressTrackFound extends CrawlProgress {
  final CrawlTrackEntry trackEntry;
  const CrawlProgressTrackFound({required this.trackEntry});
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
```

**File:** `lib/src/api/search_result.dart`

```dart
/// Search result from Rekordbox database
class SearchResult {
  final String trackId;
  final String title;
  final String artist;
  final String? album;
  final int? bpm;
  final String? key;
  final int? lengthSeconds;
  final int hotCueCount;
  final int memoryCueCount;
  final String? filePath;
  final DateTime? dateAdded;
  
  const SearchResult({
    required this.trackId,
    required this.title,
    required this.artist,
    this.album,
    this.bpm,
    this.key,
    this.lengthSeconds,
    required this.hotCueCount,
    required this.memoryCueCount,
    this.filePath,
    this.dateAdded,
  });
  
  /// Formatted duration string (e.g., "3:45")
  String get durationFormatted {
    if (lengthSeconds == null) return '--:--';
    final minutes = lengthSeconds! ~/ 60;
    final seconds = lengthSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```

### Proposed InPhase API Class

**File**: `lib/src/api/in_phase.dart`

```dart
class InPhase {
  SpotifyApi? _spotifyApi; // Changed from final to nullable
  final RekordboxDatabase? _rbDb;
  final AppDatabase _syncDb;
  final RequestPool _requestPool;
  bool _disposed = false;

  InPhase._({
    SpotifyApi? spotifyApi, // Changed to optional
    RekordboxDatabase? rbDb,
    required AppDatabase syncDb,
    required RequestPool requestPool,
  })  : _spotifyApi = spotifyApi,
        _rbDb = rbDb,
        _syncDb = syncDb,
        _requestPool = requestPool;

  /// Creates an InPhase instance WITHOUT requiring authentication
  ///
  /// [rekordboxDbPath] - Optional path to Rekordbox database. If null, Rekordbox features will be disabled.
  /// Authentication can be added later via [authenticate()] method.
  static Future<InPhase> create({
    String? rekordboxDbPath, // Removed required spotifyApi parameter
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
      spotifyApi: null, // No authentication initially
      rbDb: rbDb,
      syncDb: syncDb,
      requestPool: requestPool,
    );
  }

  /// Authenticates the InPhase instance with a Spotify API
  ///
  /// [spotifyApi] - Authenticated Spotify API instance (use [spotifyLogin] to get this)
  /// Throws [StateError] if instance is already authenticated
  Future<void> authenticate(SpotifyApi spotifyApi) async {
    _checkDisposed();
    if (_spotifyApi != null) {
      throw StateError('InPhase instance is already authenticated');
    }
    _spotifyApi = spotifyApi;
  }

  /// Logs out and clears authentication
  ///
  /// Does not dispose of the instance, just clears authentication.
  /// Config operations can still be performed after logout.
  Future<void> logout() async {
    _checkDisposed();
    _spotifyApi = null;
  }

  /// Checks if user is authenticated with Spotify
  bool get isAuthenticated {
    _checkDisposed();
    return _spotifyApi != null;
  }

  /// Gets the current Spotify user info
  ///
  /// Throws [StateError] if not authenticated
  Future<User> getCurrentUser() async {
    _checkDisposed();
    _checkAuthenticated();
    return await _spotifyApi!.me.get();
  }

  /// Gets all Spotify playlists for the authenticated user
  ///
  /// Throws [StateError] if not authenticated
  Future<List<PlaylistSimple>> getPlaylists() async {
    _checkDisposed();
    _checkAuthenticated();
    return await _spotifyApi!.playlists.me.all(50);
  }

  /// Syncs playlists from Spotify to Rekordbox
  ///
  /// Throws [StateError] if not authenticated
  /// Emits progress events via the returned stream.
  Stream<SyncProgress> syncPlaylists({
    List<String>? playlistIds,
  }) async* {
    _checkDisposed();
    _checkAuthenticated();
    _checkRekordboxAvailable();
    // ... rest of implementation
  }

  /// Crawls Spotify for new tracks and creates playlists
  ///
  /// Throws [StateError] if not authenticated
  Stream<CrawlProgress> crawl({
    List<String>? jobNames,
    DateTime? startDate,
    DateTime? endDate,
    bool dryRun = false,
  }) async* {
    _checkDisposed();
    _checkAuthenticated();
    // ... rest of implementation
  }

  /// Searches Rekordbox library for tracks
  ///
  /// Throws [StateError] if not authenticated
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    _checkDisposed();
    _checkAuthenticated();
    _checkRekordboxAvailable();
    // ... rest of implementation
  }

  // Config operations do NOT require authentication
  Future<SyncConfig> getSyncConfig() async {
    _checkDisposed();
    // No auth check - config can be viewed without auth
    return await SyncConfig.fromFile(Constants.syncConfigFile);
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    _checkDisposed();
    // No auth check - config can be saved without auth
    await config.saveToFile(Constants.syncConfigFile);
  }

  // ... other config methods (no auth required)

  void _checkAuthenticated() {
    if (_spotifyApi == null) {
      throw StateError(
        'InPhase instance is not authenticated. '
        'Call authenticate() before performing this operation.',
      );
    }
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
}
```

### Benefits of This API Design

1. **Separation of Concerns**: Instance creation is separate from authentication
2. **Better UX**: App can start immediately, show login screen, then authenticate
3. **State Management**: Authentication state is explicit and trackable
4. **Error Handling**: Clear errors when operations are attempted without auth
5. **Config Access**: Config can be viewed/edited without authentication (useful for setup)

### Migration Notes

- Existing CLI code can be updated to call `authenticate()` after `create()`
- Or CLI can use a convenience method: `InPhase.createAuthenticated(spotifyApi: ..., rekordboxDbPath: ...)`
- GUI app uses the new deferred authentication pattern

## Technical Considerations

### Coding Standards: Sealed Classes and Switch Expressions

**Always use sealed classes and switch expressions** - never use `.when()`:

1. **Sealed Classes**: Use `sealed` classes for:

   - Progress event types (`SyncProgress`, `CrawlProgress`)
   - State classes (`SyncState`, `CrawlState`, `AuthState`, etc.)
   - Result types
   - Any discriminated union pattern

**Benefits**:

   - Exhaustiveness checking at compile-time
   - Prevents missing cases
   - Better IDE support with pattern matching
   - Type-safe state machines

2. **Switch Expressions**: Always use switch expressions instead of `.when()`:

   - For `AsyncValue` handling
   - For sealed class pattern matching
   - For enum handling
   - For any pattern matching scenario

**Example**:

   ```dart
   // ✅ Good - Switch expression
   return switch (asyncValue) {
     AsyncLoading() => LoadingWidget(),
     AsyncError(:final error) => ErrorWidget(error: error),
     AsyncData(:final value) => DataWidget(data: value),
   };
   
   // ❌ Bad - Never use .when()
   asyncValue.when(
     loading: () => LoadingWidget(),
     error: (e, _) => ErrorWidget(error: e),
     data: (d) => DataWidget(data: d),
   );
   ```

3. **Pattern Matching**: Use Dart 3 pattern matching features:

   - Destructuring in patterns: `AsyncData(:final value)`
   - Guard clauses: `case SomePattern when condition =>`
   - Logical-or patterns: `case Pattern1 || Pattern2 =>`

**Reference**: [Dart Switch Expressions Documentation](https://dart.dev/language/branches#switch-expressions)

### State Management Pattern

Following the API-Repository-Riverpod-UI architecture:

1. **API Layer**: `InPhase` class from `in_phase` package
2. **Repository Layer**: Not needed (InPhase acts as repository)
3. **Riverpod Layer**: Providers that wrap InPhase methods
4. **UI Layer**: ConsumerWidgets that watch providers

### Progress Streams

For long-running operations (sync, crawl), use `StreamProvider`. Progress events should be defined as sealed classes for exhaustiveness checking:

```dart
// Progress events should be sealed classes
sealed class SyncProgress {}

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

// ... other progress event classes

// Use switch expressions to handle progress events
@riverpod
Stream<SyncProgress> syncProgress(SyncProgressRef ref) {
  final inPhase = ref.watch(inPhaseProvider).value!;
  return inPhase.syncPlaylists();
}

// In UI, use switch expressions for exhaustiveness checking
StreamBuilder<SyncProgress>(
  stream: syncProgressStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox();
    
    return switch (snapshot.data!) {
      SyncProgressStarted() => const Text('Starting sync...'),
      SyncProgressPlaylistStarted(:final playlistName) => Text('Syncing: $playlistName'),
      SyncProgressTrackProcessed(:final trackName, :final matched) => 
        Text(matched ? '✓ $trackName' : '✗ $trackName'),
      SyncProgressCompleted(:final report) => Text('Completed: ${report.tracks.length} tracks'),
      SyncProgressError(:final message) => Text('Error: $message'),
    };
  },
)
```

**Important**: Always use sealed classes for progress events and state classes to enable exhaustiveness checking with switch expressions.

### Error Handling

Use `AsyncValue` for all async operations. Always use switch expressions instead of `.when()`:

```dart
final syncState = ref.watch(syncProvider);
return switch (syncState) {
  AsyncLoading() => LoadingIndicator(),
  AsyncError(:final error, :final stackTrace) => ErrorWidget(error: error),
  AsyncData(:final value) => SyncResults(data: value),
};
```

**Important**: Never use `.when()` - always use switch expressions for `AsyncValue` handling.

### Navigation

Use Auto Route for type-safe navigation:

```dart
context.pushRoute(SyncResultsRoute(reportId: report.id));
```

### Authentication Flow

1. **App Start**: 

   - Create InPhase instance (without auth)
   - Check for cached credentials via `authProvider.checkAuthStatus()`
   - If cached credentials exist, authenticate InPhase instance
   - Show login screen if not authenticated, dashboard if authenticated

2. **User Login**:

   - User clicks "Login with Spotify" on login screen
   - Call `authProvider.login()` which:
     - Sets state to `AuthStateAuthenticating`
     - Opens browser with Spotify OAuth URL
     - User authorizes in browser
     - Browser redirects to `inphase://auth-callback?code=...`
     - App handles callback, extracts code
     - Exchange code for tokens (handled by `spotifyLogin()`)
     - Store credentials (handled by `in_phase` package)
     - Call `inPhase.authenticate(spotifyApi)` to link auth to instance
     - Set state to `AuthStateAuthenticated`
   - Navigate to dashboard (handled by route guard or listener)

3. **User Logout**:

   - Call `authProvider.logout()` which:
     - Calls `inPhase.logout()` to clear auth from instance
     - Calls `spotifyLogout()` to clear credentials
     - Set state to `AuthStateUnauthenticated`
   - Navigate to login screen

4. **Protected Operations**:

   - Operations on InPhase (sync, crawl, search) check `isAuthenticated`
   - Throw `StateError` if called without authentication
   - UI checks `authProvider` state before allowing operations

### Rekordbox Database Path

- Store path in app preferences (shared_preferences or similar)
- Allow user to select path in settings
- Validate path exists and is readable
- Show error if path invalid

### Configuration Files

- Load configs from YAML files (via `InPhase.getSyncConfig()`)
- Display in editable forms
- Save back to YAML (via `InPhase.saveSyncConfig()`)
- Validate before saving
- Show preview of changes

## Dependencies

### Core Dependencies

```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Navigation
  auto_route: ^9.3.0
  
  # Desktop Window Management
  window_manager: ^0.4.3
  
  # OAuth & Deep Linking
  url_launcher: ^6.3.1
  app_links: ^6.4.0           # Cross-platform deep linking (replaces uni_links)
  
  # Windows-specific (for URL scheme registration)
  win32_registry: ^1.1.5
  
  # File Operations
  file_picker: ^8.1.4
  path_provider: ^2.1.5
  
  # UI
  flutter_markdown: ^0.7.5
  
  # Utilities
  intl: ^0.20.2
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  shared_preferences: ^2.3.4
  equatable: ^2.0.7
  
  # Logging
  logging: ^1.3.0
  
  # Local package
  in_phase:
    path: ../in_phase
```

### Dev Dependencies

```yaml
dev_dependencies:
  # Code Generation
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.3
  auto_route_generator: ^9.0.0
  json_serializable: ^6.9.0
  freezed: ^2.5.7
  
  # Testing
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  
  # Linting
  flutter_lints: ^5.0.0
```

### build.yaml Configuration

```yaml
# build.yaml
targets:
  $default:
    builders:
      riverpod_generator:
        enabled: true
        options:
          # Generate providers for all annotated classes
      auto_route_generator:auto_router_generator:
        enabled: true
        options:
          # Use 'Route' suffix for generated routes
      freezed:
        enabled: true
        options:
          # Generate copyWith, ==, hashCode, toString
      json_serializable:
        enabled: true
        options:
          explicit_to_json: true
          include_if_null: false
```

## Key Implementation Details

### InPhase Provider

```dart
@riverpod
Future<InPhase> inPhase(InPhaseRef ref) async {
  // Get Rekordbox DB path from preferences
  final prefs = await SharedPreferences.getInstance();
  final rbPath = prefs.getString('rekordbox_db_path');
  
  // Create InPhase instance WITHOUT authentication
  // Authentication happens separately via auth provider
  final inPhase = await InPhase.create(
    rekordboxDbPath: rbPath,
  );
  
  // Check if we have cached credentials and authenticate if available
  final authState = ref.read(authProvider);
  if (authState case AuthStateAuthenticated(:final spotifyApi)) {
    await inPhase.authenticate(spotifyApi);
  }
  
  return inPhase;
}
```

**Note**:

- InPhase instance is created without authentication
- Authentication is handled separately via `authProvider.login()`
- When authentication succeeds, call `inPhase.authenticate(spotifyApi)` to link auth to instance
- Operations on InPhase will throw `StateError` if called without authentication (except config operations)

### Sync Provider with Cancellation Support

```dart
// lib/features/sync/data/models/sync_state.dart

/// State for sync operations - use sealed classes for exhaustiveness
sealed class SyncState {
  const SyncState();
}

class SyncStateIdle extends SyncState {
  const SyncStateIdle();
}

class SyncStateRunning extends SyncState {
  final SyncProgress currentProgress;
  final List<SyncTrackEntry> processedTracks;
  final int totalPlaylists;
  final int completedPlaylists;
  
  const SyncStateRunning({
    required this.currentProgress,
    this.processedTracks = const [],
    this.totalPlaylists = 0,
    this.completedPlaylists = 0,
  });
  
  double get progressPercent => 
    totalPlaylists > 0 ? completedPlaylists / totalPlaylists : 0;
}

class SyncStateCompleted extends SyncState {
  final SyncReport report;
  final Duration duration;
  
  const SyncStateCompleted({
    required this.report,
    required this.duration,
  });
}

class SyncStateCancelled extends SyncState {
  final int playlistsCompleted;
  
  const SyncStateCancelled({required this.playlistsCompleted});
}

class SyncStateError extends SyncState {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  
  const SyncStateError({
    required this.message,
    this.error,
    this.stackTrace,
  });
}
```
```dart
// lib/features/sync/presentation/providers/sync_providers.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:in_phase/in_phase_api.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true) // Keep alive to preserve state during navigation
class SyncNotifier extends _$SyncNotifier {
  StreamSubscription<SyncProgress>? _syncSubscription;
  bool _isCancelled = false;
  DateTime? _startTime;
  
  @override
  SyncState build() {
    // Cleanup subscription when provider is disposed
    ref.onDispose(() {
      _syncSubscription?.cancel();
    });
    
    return const SyncStateIdle();
  }
  
  /// Starts syncing playlists
  /// 
  /// [playlistIds] - Optional list of specific playlists to sync.
  /// If null, syncs all playlists matching config patterns.
  Future<void> startSync({List<String>? playlistIds}) async {
    // Prevent starting if already running
    if (state case SyncStateRunning()) {
      return;
    }
    
    _isCancelled = false;
    _startTime = DateTime.now();
    
    final processedTracks = <SyncTrackEntry>[];
    var completedPlaylists = 0;
    var totalPlaylists = 0;
    
    try {
      final inPhase = await ref.read(inPhaseProvider.future);
      final progressStream = inPhase.syncPlaylists(playlistIds: playlistIds);
      
      // Start listening to progress stream
      _syncSubscription = progressStream.listen(
        (progress) {
          if (_isCancelled) {
            _syncSubscription?.cancel();
            state = SyncStateCancelled(playlistsCompleted: completedPlaylists);
            return;
          }
          
          // Update state based on progress event
          state = switch (progress) {
            SyncProgressStarted(:final playlistCount) => () {
              totalPlaylists = playlistCount;
              return SyncStateRunning(
                currentProgress: progress,
                totalPlaylists: totalPlaylists,
              );
            }(),
            
            SyncProgressPlaylistStarted() => SyncStateRunning(
              currentProgress: progress,
              processedTracks: processedTracks,
              totalPlaylists: totalPlaylists,
              completedPlaylists: completedPlaylists,
            ),
            
            SyncProgressTrackProcessed(:final trackEntry) => () {
              processedTracks.add(trackEntry);
              return SyncStateRunning(
                currentProgress: progress,
                processedTracks: List.unmodifiable(processedTracks),
                totalPlaylists: totalPlaylists,
                completedPlaylists: completedPlaylists,
              );
            }(),
            
            SyncProgressPlaylistCompleted() => () {
              completedPlaylists++;
              return SyncStateRunning(
                currentProgress: progress,
                processedTracks: processedTracks,
                totalPlaylists: totalPlaylists,
                completedPlaylists: completedPlaylists,
              );
            }(),
            
            SyncProgressCompleted(:final report) => SyncStateCompleted(
              report: report,
              duration: DateTime.now().difference(_startTime!),
            ),
            
            SyncProgressError(:final message, :final error) => SyncStateError(
              message: message,
              error: error,
            ),
          };
        },
        onError: (Object error, StackTrace stackTrace) {
          state = SyncStateError(
            message: 'Sync failed unexpectedly',
            error: error,
            stackTrace: stackTrace,
          );
        },
        onDone: () {
          // Stream completed - state should already be updated
        },
        cancelOnError: true,
      );
      
    } catch (e, stack) {
      state = SyncStateError(
        message: 'Failed to start sync: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }
  
  /// Cancels the current sync operation
  void cancelSync() {
    if (state case SyncStateRunning()) {
      _isCancelled = true;
      // The stream listener will handle the rest
    }
  }
  
  /// Resets to idle state
  void reset() {
    _syncSubscription?.cancel();
    _isCancelled = false;
    _startTime = null;
    state = const SyncStateIdle();
  }
}

// In UI, use switch expressions to handle state
Widget buildSyncUI(WidgetRef ref) {
  final syncState = ref.watch(syncProvider);
  
  return switch (syncState) {
    AsyncLoading() => const LoadingIndicator(),
    AsyncError(:final error, :final stackTrace) => ErrorWidget(error: error),
    AsyncData(:final value) => switch (value) {
      SyncStateIdle() => const Text('Ready to sync'),
      SyncStateRunning(:final progress) => switch (progress) {
        SyncProgressPlaylistStarted(:final playlistName) => Text('Syncing: $playlistName'),
        SyncProgressTrackProcessed(:final trackName, :final matched) => 
          Text(matched ? '✓ $trackName' : '✗ $trackName'),
        _ => const CircularProgressIndicator(),
      },
      SyncStateCompleted(:final report) => Text('Completed: ${report.tracks.length} tracks'),
      SyncStateError(:final message) => Text('Error: $message'),
    },
  };
}
```

### Route Guard

**File:** `lib/core/router/guards/auth_guard.dart`

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/data/models/auth_state.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../app_router.dart';

/// Route guard that protects routes requiring authentication
/// 
/// Uses the [authProvider] to check authentication state.
/// Redirects to login if not authenticated.
class AuthGuard extends AutoRouteGuard {
  final ProviderContainer container;
  
  AuthGuard(this.container);
  
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final authState = container.read(authProvider);
    
    switch (authState) {
      case AuthStateAuthenticated():
        // User is authenticated, allow navigation
        resolver.next(true);
        
      case AuthStateAuthenticating():
        // Authentication in progress, wait
        // Could show loading or redirect to splash
        resolver.next(false);
        
      case AuthStateUnauthenticated():
      case AuthStateError():
        // Not authenticated, redirect to login
        // Pass the intended destination for redirect after login
        resolver.redirect(
          LoginRoute(
            onLoginSuccess: () {
              // After successful login, continue to original destination
              resolver.next(true);
            },
          ),
          replace: true,
        );
    }
  }
}
```

**Integrating AuthGuard with Router:**

```dart
// lib/core/router/app_router.dart
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStacether kRouter {
  final ProviderContainer container;
  
  AppRouter(this.container);
  
  @override
  late final List<AutoRouteGuard> guards = [
    // Global guards can be added here
  ];
  
  late final _authGuard = AuthGuard(container);
  
  @override
  List<AutoRoute> get routes => [
    // Public routes
    AutoRoute(page: SplashRoute.page, initial: true, path: '/'),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),
    
    // Protected routes (require authentication)
    AutoRoute(
      page: DashboardRoute.page, 
      path: '/dashboard',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: SyncRoute.page, 
      path: '/sync',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: SyncResultsRoute.page, 
      path: '/sync/results/:reportId',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: CrawlRoute.page, 
      path: '/crawl',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: CrawlJobEditorRoute.page, 
      path: '/crawl/job/:jobName',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: CrawlResultsRoute.page, 
      path: '/crawl/results/:reportId',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: SearchRoute.page, 
      path: '/search',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ConfigRoute.page, 
      path: '/config',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: SyncConfigEditorRoute.page, 
      path: '/config/sync',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: CrawlConfigEditorRoute.page, 
      path: '/config/crawl',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: SettingsRoute.page, 
      path: '/settings',
      guards: [_authGuard],
    ),
    
    // 404 fallback
    AutoRoute(page: NotFoundRoute.page, path: '*'),
  ];
}
```

**Note**: Route guard receives the `ProviderContainer` via constructor, avoiding the fragile `ProviderScope.containerOf()` pattern. The container is passed from `main.dart` where we have access to it.

## Success Criteria

### MVP (Minimum Viable Product)

- ✅ Spotify authentication working
- ✅ Dashboard displays and navigates
- ✅ Sync feature works with progress display
- ✅ Basic configuration viewing
- ✅ Error handling and user feedback

### Full Feature Set

- ✅ All MVP features
- ✅ Crawl feature with job management
- ✅ Search feature
- ✅ Configuration editing (sync and crawl)
- ✅ Settings screen
- ✅ Report viewing
- ✅ Dark mode support
- ✅ Keyboard shortcuts

## Timeline Estimate

- **Phase 1**: 2-3 days (Setup and foundation)
- **Phase 2**: 3-4 days (API integration and auth)
- **Phase 3**: 2-3 days (Navigation setup)
- **Phase 4**: 10-14 days (Core features)
- **Phase 5**: 4-5 days (Settings and polish)
- **Phase 6**: 3-4 days (Testing)
- **Phase 7**: 2-3 days (Build and deployment)

**Total**: 26-36 days (approximately 5-7 weeks)

## Risks and Mitigations

### Risk: OAuth Flow Complexity

- **Mitigation**: Use proven patterns, test thoroughly on all platforms

### Risk: Long-running Operations Blocking UI

- **Mitigation**: Use isolates for heavy computation, streams for progress updates

### Risk: State Management Complexity

- **Mitigation**: Follow Riverpod best practices, start simple, refactor as needed

### Risk: Configuration File Corruption

- **Mitigation**: Validate before saving, backup before writes, show clear error messages

### Risk: Rekordbox Database Access Issues

- **Mitigation**: Validate path, handle errors gracefully, provide clear error messages

## Next Steps

1. **Prerequisite**: Ensure `InPhase` API class exists in `in_phase` package (Phase 1 from GUI_FEASIBILITY_ANALYSIS.md)
2. Initialize git repository and create Flutter project structure
3. Setup dependencies using `dart pub add` and code generation
4. Implement authentication flow
5. Build core features incrementally, committing at milestones
6. Use Dart MCP for analysis and testing throughout development
7. Test thoroughly
8. Polish UI/UX
9. Build and distribute

## Development Workflow Summary

- **Code Analysis**: Use Dart MCP first, fall back to static analysis/linter
- **Dependencies**: Always use `dart pub add` instead of manual edits
- **Version Control**: Git initialized at start, conventional commits at milestones
- **Commits**: Use format `type: description` (feat:, fix:, chore:, etc.)

## Design Decisions and FAQ

This section documents key decisions and answers common questions that may arise during implementation.

### Q: Why do we need `tryRestoreSpotifySession()` separate from `spotifyLogin()`?

**Decision:** These must be separate functions with distinct behaviors:

| Function | Behavior | When to Use |

|----------|----------|-------------|

| `tryRestoreSpotifySession()` | Only checks cached credentials, returns `null` if none exist | App startup, checking if user is already logged in |

| `spotifyLogin()` | Opens browser for OAuth if no cached credentials | User explicitly clicks "Login" button |

**Problem it solves:** Using `spotifyLogin()` to check auth status would open a browser window every time the app starts if no cached credentials exist - terrible UX!

**Implementation:**

- `tryRestoreSpotifySession()` simply exposes the existing `_attemptCachedCredentialsLogin()` private function
- Returns `SpotifyApi?` (nullable) - `null` means no cached session
- Never triggers OAuth flow or opens browser
- May throw if cached credentials are corrupt (rare)

### Q: What happens if the Rekordbox database is locked (being used by Rekordbox)?

**Decision:** Show a clear error message explaining the situation with a "Retry" button.

```dart
// Example error message
'Rekordbox database is locked. Please close Rekordbox and try again.'
```

The `rekorddart` package should handle this gracefully by throwing a specific exception that we can catch.

### Q: How should we handle Spotify rate limits in the GUI?

**Decision:**

1. Show a progress message: "Rate limited. Waiting X seconds..."
2. Use exponential backoff handled by the `in_phase` package
3. The GUI just shows the current status from progress events
4. Add a "Pause" button that lets users manually pause long operations

### Q: Should sync/crawl operations be resumable?

**Decision:** Not for MVP. Sync operations are typically fast enough.

**Future Enhancement:** Store partial progress in SQLite and allow resuming. This is complex and can be added later if needed.

### Q: How to handle multiple Spotify accounts?

**Decision:** Not supported in MVP. The app uses one Spotify account at a time.

**Logout + Login:** Users can logout and login with a different account.

### Q: Should config changes require confirmation before saving?

**Decision:** Yes, for any destructive changes. Show a confirmation dialog when:

- Removing patterns/jobs
- Resetting config to defaults
- Overwriting with imported config

For simple edits (adding patterns, changing options), save directly with a success snackbar.

### Q: What's the maximum number of playlists to display?

**Decision:** Show all playlists (Spotify typically limits to ~10,000 per user). Use a virtualized list (`ListView.builder`) for performance. The list is already lazy-loaded.

### Q: Should there be a "dry run" mode visible in the UI?

**Decision:** Yes for Crawl, not for Sync.

- **Crawl:** Add a "Preview Mode" checkbox that shows what playlists would be created without actually creating them
- **Sync:** Dry run doesn't make as much sense - just let users select playlists and review before syncing

### Q: What should happen if the app is closed during sync/crawl?

**Decision:**

1. Show a warning dialog: "Operation in progress. Are you sure you want to quit?"
2. If user confirms, cancel the operation gracefully
3. Partial progress is lost (not resumable in MVP)
4. Use `window_manager` to intercept close events
```dart
windowManager.addListener(WindowCloseListener(
  onWindowClose: () async {
    if (syncState is SyncStateRunning) {
      final confirmed = await showConfirmationDialog(...);
      if (!confirmed) return false; // Prevent close
    }
    return true; // Allow close
  },
));
```


### Q: Should reports be deletable?

**Decision:** Yes. Reports are stored as files. Add a "Delete" action in the report viewer with confirmation dialog.

### Q: How to handle Rekordbox database schema version mismatches?

**Decision:** The `rekorddart` package handles this. If incompatible:

1. Show error: "Rekordbox version not supported. Please update InPhase."
2. Link to GitHub releases for updates
3. Allow config editing without Rekordbox access

### Q: Where are reports stored?

**Decision:** In the app data directory alongside configs:

- `~/.in_phase/reports/sync/` - Sync reports as JSON
- `~/.in_phase/reports/crawl/` - Crawl reports as JSON
- Reports include timestamp in filename: `sync_2024-01-15_143022.json`

### Q: How to validate Rekordbox database path?

**Decision:** Check for expected files:

1. Look for `master.db` in the directory
2. Try to connect with `rekorddart`
3. If connection fails, show specific error message
4. Don't require exact path - let user point to parent folder and search
```dart
Future<String?> findRekordboxDatabase(String basePath) async {
  final candidates = [
    '$basePath/master.db',
    '$basePath/rekordbox/master.db',
    '$basePath/Pioneer/rekordbox/master.db',
  ];
  
  for (final path in candidates) {
    if (await File(path).exists()) {
      return path;
    }
  }
  return null;
}
```


### Q: What about accessibility?

**Decision:** Follow Material 3 accessibility guidelines:

1. All interactive elements have semantic labels
2. Sufficient color contrast (enforced by Material 3)
3. Keyboard navigation works for all screens
4. Focus indicators visible
5. Screen reader support via Flutter's built-in semantics

### Q: How to handle logging for debugging?

**Decision:** Use the `logging` package:

1. Log to console in debug mode
2. Optionally save logs to file in app data directory
3. Add "Export Logs" button in Settings for bug reports
4. Log levels: debug (dev only), info, warning, error
```dart
// Configure logging
Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
Logger.root.onRecord.listen((record) {
  debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
  // Also write to file if enabled
});
```


## Project Checklist Summary

Before starting implementation, ensure:

- [ ] `in_phase` package has `InPhase` API class with deferred auth
- [ ] `in_phase` package exports all needed types via `in_phase_api.dart`
- [ ] Progress events are sealed classes in `in_phase`
- [ ] All questions above have clear answers

During implementation:

- [ ] Use `dart pub add` for all dependencies
- [ ] Run `dart run build_runner build` after creating new providers/routes
- [ ] Commit at each phase completion with conventional commits
- [ ] Use Dart MCP for analysis when available
- [ ] Test on all three platforms (macOS, Windows, Linux)

This plan provides a comprehensive roadmap for building a production-ready Flutter desktop GUI application for InPhase.