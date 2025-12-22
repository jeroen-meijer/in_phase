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
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # MaterialApp setup
│   │
│   ├── core/
│   │   ├── router/
│   │   │   ├── app_router.dart           # Auto Route configuration
│   │   │   └── guards/
│   │   │       └── auth_guard.dart       # Authentication guard
│   │   ├── theme/
│   │   │   ├── app_theme.dart            # Theme configuration
│   │   │   └── app_colors.dart           # Color definitions
│   │   ├── constants/
│   │   │   └── app_constants.dart        # App-wide constants
│   │   └── utils/
│   │       ├── file_picker_utils.dart    # File picker helpers
│   │       └── oauth_utils.dart          # OAuth callback handling
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── auth_state.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── auth_providers.dart
│   │   │   │   ├── screens/
│   │   │   │   │   └── login_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── oauth_webview.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── dashboard_providers.dart
│   │   │   │   ├── screens/
│   │   │   │   │   └── dashboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── feature_card.dart
│   │   │   │       └── quick_stats.dart
│   │   │
│   │   ├── sync/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── sync_state.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── sync_providers.dart
│   │   │   │   ├── screens/
│   │   │   │   │   ├── sync_screen.dart
│   │   │   │   │   └── sync_results_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── playlist_selector.dart
│   │   │   │       ├── sync_progress_indicator.dart
│   │   │   │       ├── track_match_list.dart
│   │   │   │       └── sync_report_viewer.dart
│   │   │
│   │   ├── crawl/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── crawl_state.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── crawl_providers.dart
│   │   │   │   ├── screens/
│   │   │   │   │   ├── crawl_screen.dart
│   │   │   │   │   ├── crawl_job_editor_screen.dart
│   │   │   │   │   └── crawl_results_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── job_list.dart
│   │   │   │       ├── crawl_progress_indicator.dart
│   │   │   │       ├── source_editor.dart
│   │   │   │       └── crawl_report_viewer.dart
│   │   │
│   │   ├── search/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── search_result.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── search_providers.dart
│   │   │   │   ├── screens/
│   │   │   │   │   └── search_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── search_bar.dart
│   │   │   │       ├── track_result_list.dart
│   │   │   │       └── track_detail_card.dart
│   │   │
│   │   ├── config/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── config_form_state.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── config_providers.dart
│   │   │   │   ├── screens/
│   │   │   │   │   ├── config_screen.dart
│   │   │   │   │   ├── sync_config_editor_screen.dart
│   │   │   │   │   └── crawl_config_editor_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── pattern_editor.dart
│   │   │   │       ├── folder_selector.dart
│   │   │   │       ├── camelot_key_selector.dart
│   │   │   │       ├── job_editor_form.dart
│   │   │   │       └── source_list_editor.dart
│   │   │
│   │   └── settings/
│   │       ├── presentation/
│   │       │   ├── providers/
│   │       │   │   └── settings_providers.dart
│   │       │   ├── screens/
│   │       │   │   └── settings_screen.dart
│   │       │   └── widgets/
│   │       │       ├── rekordbox_path_selector.dart
│   │       │       ├── cache_management.dart
│   │       │       └── theme_selector.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── loading_indicator.dart
│       │   ├── error_widget.dart
│       │   ├── empty_state.dart
│       │   └── progress_bar.dart
│       └── models/
│           └── common_types.dart
│
├── test/
│   └── ... (test files)
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
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
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthStateUnauthenticated();
  
  Future<void> login() async {
    state = const AuthStateAuthenticating();
    
    try {
      final spotifyApi = await spotifyLogin(
        redirectAndGetResponseUri: guiOAuthCallback,
        useCache: true,
      );
      
      final user = await spotifyApi.me.get();
      
      // Authenticate InPhase instance
      final inPhase = ref.read(inPhaseProvider).value;
      if (inPhase != null) {
        await inPhase.authenticate(spotifyApi);
      }
      
      state = AuthStateAuthenticated(
        spotifyApi: spotifyApi,
        user: user,
      );
    } catch (e, stack) {
      state = AuthStateError(
        message: 'Authentication failed: $e',
        error: e,
      );
    }
  }
  
  Future<void> logout() async {
    final currentState = state;
    if (currentState case AuthStateAuthenticated(:final spotifyApi)) {
      await spotifyLogout();
      
      // Clear authentication from InPhase instance
      final inPhase = ref.read(inPhaseProvider).value;
      if (inPhase != null) {
        await inPhase.logout();
      }
    }
    
    state = const AuthStateUnauthenticated();
  }
  
  Future<void> checkAuthStatus() async {
    // Check if we have cached credentials
    try {
      final spotifyApi = await spotifyLogin(
        redirectAndGetResponseUri: guiOAuthCallback,
        useCache: true,
      );
      
      final user = await spotifyApi.me.get();
      
      // Authenticate InPhase instance
      final inPhase = ref.read(inPhaseProvider).value;
      if (inPhase != null) {
        await inPhase.authenticate(spotifyApi);
      }
      
      state = AuthStateAuthenticated(
        spotifyApi: spotifyApi,
        user: user,
      );
    } catch (_) {
      state = const AuthStateUnauthenticated();
    }
  }
}
```

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

**Example Implementation:**

```dart
// In oauth_utils.dart
Future<String> guiOAuthCallback(Uri authUri) async {
  // Open browser with auth URL
  if (!await launchUrl(authUri)) {
    throw Exception('Failed to open browser');
  }
  
  // Set up URL scheme listener
  final completer = Completer<String>();
  StreamSubscription? linkSubscription;
  
  linkSubscription = linkStream.listen((String? link) {
    if (link != null && link.startsWith('inphase://auth-callback')) {
      linkSubscription?.cancel();
      completer.complete(link);
    }
  }, onError: (error) {
    linkSubscription?.cancel();
    completer.completeError(error);
  });
  
  // Timeout after 5 minutes
  Timer(const Duration(minutes: 5), () {
    if (!completer.isCompleted) {
      linkSubscription?.cancel();
      completer.completeError(TimeoutException('OAuth timeout'));
    }
  });
  
  return completer.future;
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

**State Management:**

- Use `StateProvider` for search query
- Use `FutureProvider.autoDispose.family` for search results
- Implement debouncing (500ms delay)
- Use switch expressions (never `.when()`) to handle `AsyncValue` from `FutureProvider`

**UI Flow:**

1. User types in search bar
2. Debounce and trigger search
3. Display results in list
4. Show loading indicator during search
5. Display track details on tap

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
- `lib/shared/widgets/error_widget.dart` (enhance)

**Commit:** `feat: implement global error handling with user-friendly messages`

### 5.4 UI/UX Polish

**Tasks:**

- Add animations and transitions
- Implement pull-to-refresh where applicable
- Add keyboard shortcuts
- Improve loading states
- Add tooltips and help text
- Implement responsive layouts

## Phase 6: Testing

### 6.1 Unit Tests

**Tasks:**

- Test providers in isolation
- Mock `InPhase` API
- Test state transitions
- Test error handling
- Use Dart MCP to run tests and verify coverage

**Files to Create:**

- `test/features/sync/presentation/providers/sync_providers_test.dart`
- `test/features/crawl/presentation/providers/crawl_providers_test.dart`
- `test/features/search/presentation/providers/search_providers_test.dart`
- `test/features/config/presentation/providers/config_providers_test.dart`

**Commit:** `test: add unit tests for providers`

### 6.2 Widget Tests

**Tasks:**

- Test screen widgets
- Test form validation
- Test navigation
- Test user interactions
- Use Dart MCP to run widget tests

**Files to Create:**

- `test/features/sync/presentation/screens/sync_screen_test.dart`
- `test/features/crawl/presentation/screens/crawl_screen_test.dart`
- `test/features/search/presentation/screens/search_screen_test.dart`

**Commit:** `test: add widget tests for screens`

### 6.3 Integration Tests

**Tasks:**

- Test complete user flows
- Test authentication flow
- Test sync flow end-to-end
- Test crawl flow end-to-end

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

## Required InPhase API Changes

**Important**: The `in_phase` package API must be modified to support deferred authentication. These changes should be implemented in the `in_phase` package before building the GUI app.

### Proposed API Changes

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
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  auto_route: ^9.3.0
  auto_route_annotations: ^9.3.0
  url_launcher: ^6.2.0
  file_picker: ^6.1.0
  flutter_markdown: ^0.6.18
  intl: ^0.20.2
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.2
  in_phase:
    path: ../in_phase
```

### Dev Dependencies

```yaml
dev_dependencies:
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  auto_route_generator: ^9.3.0
  json_serializable: ^6.7.1
  freezed: ^2.4.7
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

### Sync Provider

```dart
// State should be a sealed class for exhaustiveness checking
sealed class SyncState {
  const SyncState();
}

class SyncStateIdle extends SyncState {
  const SyncStateIdle();
}

class SyncStateRunning extends SyncState {
  final SyncProgress progress;
  const SyncStateRunning({required this.progress});
}

class SyncStateCompleted extends SyncState {
  final SyncReport report;
  const SyncStateCompleted({required this.report});
}

class SyncStateError extends SyncState {
  final String message;
  final Object? error;
  const SyncStateError({required this.message, this.error});
}

@riverpod
class Sync extends _$Sync {
  @override
  FutureOr<SyncState> build() => const SyncStateIdle();
  
  Future<void> startSync({List<String>? playlistIds}) async {
    state = const AsyncValue.loading();
    
    final inPhase = await ref.read(inPhaseProvider.future);
    final progressStream = inPhase.syncPlaylists(playlistIds: playlistIds);
    
    await for (final progress in progressStream) {
      // Update state based on progress using switch expression
      state = AsyncValue.data(switch (progress) {
        SyncProgressStarted() => const SyncStateIdle(),
        SyncProgressPlaylistStarted() || SyncProgressTrackProcessed() => 
          SyncStateRunning(progress: progress),
        SyncProgressCompleted(:final report) => SyncStateCompleted(report: report),
        SyncProgressError(:final message, :final error) => 
          SyncStateError(message: message, error: error),
      });
    }
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

```dart
class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final container = ProviderScope.containerOf(router.navigatorKey.currentContext!);
    final authState = container.read(authProvider);
    
    // Use switch expression to check authentication state
    switch (authState) {
      AuthStateUnauthenticated() || AuthStateError():
        resolver.redirect(LoginRoute());
      AuthStateAuthenticating():
        resolver.next(false); // Wait for authentication to complete
      AuthStateAuthenticated():
        resolver.next(true); // Allow navigation
    }
  }
}
```

**Note**: Route guard checks `authProvider` (authentication state) rather than `inPhaseProvider`, since InPhase can exist without authentication.

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

This plan provides a comprehensive roadmap for building a production-ready Flutter desktop GUI application for InPhase.