import 'package:in_phase/src/misc/misc.dart';

/// Maps a Rekordbox key name (natural like "Am"/"F#" or Camelot like "8A")
/// to Engine DJ's key integer, or null if the key cannot be parsed.
///
/// Engine stores keys as the ordinal of libdjinterop's `musical_key` enum,
/// which walks the Camelot wheel: 0 = C major (8B), 1 = A minor (8A),
/// 2 = G major (9B), 3 = E minor (9A), and so on around the wheel.
int? mapKeyToEngine(String? keyName) {
  final camelotName = mapKeyToCamelot(keyName);
  if (camelotName == null) return null;
  final camelot = CamelotKey.fromString(camelotName);
  if (camelot == null) return null;

  return switch (camelot) {
    CamelotKey.b8 => 0, // C major
    CamelotKey.a8 => 1, // A minor
    CamelotKey.b9 => 2, // G major
    CamelotKey.a9 => 3, // E minor
    CamelotKey.b10 => 4, // D major
    CamelotKey.a10 => 5, // B minor
    CamelotKey.b11 => 6, // A major
    CamelotKey.a11 => 7, // F# minor
    CamelotKey.b12 => 8, // E major
    CamelotKey.a12 => 9, // Db minor
    CamelotKey.b1 => 10, // B major
    CamelotKey.a1 => 11, // Ab minor
    CamelotKey.b2 => 12, // F# major
    CamelotKey.a2 => 13, // Eb minor
    CamelotKey.b3 => 14, // Db major
    CamelotKey.a3 => 15, // Bb minor
    CamelotKey.b4 => 16, // Ab major
    CamelotKey.a4 => 17, // F minor
    CamelotKey.b5 => 18, // Eb major
    CamelotKey.a5 => 19, // C minor
    CamelotKey.b6 => 20, // Bb major
    CamelotKey.a6 => 21, // G minor
    CamelotKey.b7 => 22, // F major
    CamelotKey.a7 => 23, // D minor
  };
}
