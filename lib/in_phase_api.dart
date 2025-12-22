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
export 'src/spotify/types.dart'
    show SpotifyPlaylistId, SpotifyTrackId, RekordboxSongId;

// Search result type
export 'src/api/search_result.dart';

// Authentication functions
export 'src/spotify/api.dart'
    show spotifyLogin, spotifyLogout, tryRestoreSpotifySession;

// Re-export spotify User type for auth state
export 'package:spotify/spotify.dart' show User, SpotifyApi, PlaylistSimple;
