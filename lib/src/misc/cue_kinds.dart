import 'package:collection/collection.dart';

/// Represents the different types of cues in Rekordbox.
///
/// Rekordbox uses:
/// - Kind 0 = Memory cue
/// - Kind 1-3 = Hot cue slots A-C (slots 1-3)
/// - Kind 5-9 = Hot cue slots D-H (slots 4-8)
/// - Kind 4 is skipped (not used)
/// - Other Kind values may represent loops or other marker types
enum CueKind {
  /// Memory cue (Kind 0)
  memory(0, 'Memory Cue'),

  /// Hot cue slot A (Kind 1)
  hotCueA(1, 'Hot Cue A', letter: 'A'),

  /// Hot cue slot B (Kind 2)
  hotCueB(2, 'Hot Cue B', letter: 'B'),

  /// Hot cue slot C (Kind 3)
  hotCueC(3, 'Hot Cue C', letter: 'C'),

  /// Hot cue slot D (Kind 5)
  hotCueD(5, 'Hot Cue D', letter: 'D'),

  /// Hot cue slot E (Kind 6)
  hotCueE(6, 'Hot Cue E', letter: 'E'),

  /// Hot cue slot F (Kind 7)
  hotCueF(7, 'Hot Cue F', letter: 'F'),

  /// Hot cue slot G (Kind 8)
  hotCueG(8, 'Hot Cue G', letter: 'G'),

  /// Hot cue slot H (Kind 9)
  hotCueH(9, 'Hot Cue H', letter: 'H')
  ;

  const CueKind(this.kind, this.displayName, {this.letter});

  /// The Rekordbox Kind value for this cue type.
  final int kind;

  /// Human-readable display name.
  final String displayName;

  /// Hot cue slot letter (A-H), null for memory cues.
  final String? letter;

  /// Checks if this is a hot cue (not a memory cue).
  bool get isHotCue => this != CueKind.memory;

  /// Checks if this is a memory cue.
  bool get isMemoryCue => this == CueKind.memory;

  /// Gets the CueKind enum value from a Rekordbox Kind value.
  ///
  /// Returns null if the Kind value doesn't match any known cue type.
  static CueKind? fromKind(int? kind) {
    if (kind == null) return null;
    try {
      return CueKind.values.firstWhere((ck) => ck.kind == kind);
    } catch (_) {
      return null;
    }
  }

  /// Gets the CueKind enum value from a hot cue slot letter (A-H).
  ///
  /// Returns null if the letter is invalid.
  static CueKind? fromLetter(String letter) {
    return CueKind.values.firstWhereOrNull(
      (ck) => ck.letter?.toLowerCase() == letter.toLowerCase(),
    );
  }

  /// All hot cue types (A-H).
  static const List<CueKind> hotCues = [
    hotCueA,
    hotCueB,
    hotCueC,
    hotCueD,
    hotCueE,
    hotCueF,
    hotCueG,
    hotCueH,
  ];

  /// All valid hot cue letters (A-H).
  static List<String> get allLetters =>
      hotCues.map((ck) => ck.letter!).toList();

  /// Returns the next hot cue in the sequence, or `null` if there is none or if
  /// this is a memory cue.
  CueKind? get next => CueKind.values.elementAtOrNull(index + 1);
}
