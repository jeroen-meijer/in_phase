import 'package:meta/meta.dart';
import 'package:rekorddart/rekorddart.dart';

/// Key name and BPM for a Rekordbox content row.
@immutable
class RekordboxSongMeta {
  const RekordboxSongMeta({this.keyName, this.bpmCenti});

  /// From `djmdKey.ScaleName` (natural or Camelot).
  final String? keyName;

  /// BPM * 100 as stored by Rekordbox (`djmdContent.BPM`).
  final int? bpmCenti;

  /// Whole BPM for display (Rekordbox-style).
  int? get bpm => bpmCenti == null ? null : (bpmCenti! / 100).round();

  bool get hasMetadata => keyName != null || bpmCenti != null;
}

/// Loads key + BPM for all non-deleted Rekordbox contents.
///
/// Map keys are `djmdContent.ID`.
Future<Map<String, RekordboxSongMeta>> loadRekordboxSongMeta(
  RekordboxDatabase rbDb,
) async {
  final keyById = {
    for (final key in await rbDb.select(rbDb.djmdKey).get())
      if (key.id != null && key.scaleName != null) key.id!: key.scaleName!,
  };

  final contents = await (rbDb.select(
    rbDb.djmdContent,
  )..where((c) => c.rbLocalDeleted.equals(0))).get();

  return {
    for (final content in contents)
      if (content.id != null)
        content.id!: RekordboxSongMeta(
          keyName: content.keyID != null ? keyById[content.keyID] : null,
          bpmCenti: content.bpm,
        ),
  };
}

/// Convenience: content id → key scale name only (may be null).
Future<Map<String, String?>> loadRekordboxSongKeys(
  RekordboxDatabase rbDb,
) async {
  final meta = await loadRekordboxSongMeta(rbDb);
  return {for (final entry in meta.entries) entry.key: entry.value.keyName};
}
