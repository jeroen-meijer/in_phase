/// Search result from Rekordbox database
class SearchResult {
  const SearchResult({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.hotCueCount,
    required this.memoryCueCount,
    this.album,
    this.bpm,
    this.key,
    this.lengthSeconds,
    this.filePath,
    this.dateAdded,
  });
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

  /// Formatted duration string (e.g., "3:45")
  String get durationFormatted {
    if (lengthSeconds == null) return '--:--';
    final minutes = lengthSeconds! ~/ 60;
    final seconds = lengthSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
