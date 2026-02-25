/// Formats milliseconds as M:SS (e.g. 105000 → "1:45").
String formatDurationMs(int ms) {
  final totalMs = ms.clamp(0, 0x7FFFFFFFFFFFFFFF);
  final minutes = totalMs ~/ 60000;
  final remainingSeconds = (totalMs % 60000) ~/ 1000;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

/// Parses position string "M:SS" to milliseconds (e.g. "1:15" → 75000).
///
/// Returns null if format is invalid.
int? parsePositionToMs(String s) {
  final match = RegExp(r'^(\d+):(\d{2})$').firstMatch(s.trim());
  if (match == null) return null;
  final minutes = int.tryParse(match.group(1)!);
  final seconds = int.tryParse(match.group(2)!);
  if (minutes == null || seconds == null) return null;
  return minutes * 60000 + seconds * 1000;
}
