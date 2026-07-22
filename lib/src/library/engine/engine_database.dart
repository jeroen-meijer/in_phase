import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:in_phase/src/library/convert/track_mapper.dart';
import 'package:in_phase/src/library/engine/engine_album_art.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Default Engine Library location on desktop.
String defaultEngineLibraryPath(String userHomeDirectory) =>
    p.join(userHomeDirectory, 'Music', 'Engine Library');

/// Path to `m.db` inside an Engine Library directory (Database2 layout,
/// Engine 2.x and later).
String engineDatabasePath(String engineLibraryPath) =>
    p.join(engineLibraryPath, 'Database2', 'm.db');

/// A row from Engine's `AlbumArt` table.
@immutable
class EngineAlbumArtRow {
  const EngineAlbumArtRow({required this.id, this.hash});

  final int id;
  final String? hash;
}

/// An existing Engine `Track` row (with joined `PerformanceData` blobs) used
/// to diff against the desired state during sync.
@immutable
class EngineTrackRow {
  const EngineTrackRow({
    required this.id,
    required this.columns,
    this.pdbImportKey,
    this.path,
    this.trackData,
    this.beatData,
    this.quickCues,
    this.loops,
  });

  final int id;
  final int? pdbImportKey;
  final String? path;

  /// Metadata columns subject to sync, keyed by column name.
  final Map<String, Object?> columns;

  final Uint8List? trackData;
  final Uint8List? beatData;
  final Uint8List? quickCues;
  final Uint8List? loops;
}

/// Wraps direct sqlite3 access to Engine DJ's `m.db`.
///
/// Only inserts and updates rows; never modifies the schema, which Engine
/// validates strictly.
class EngineDatabase {
  EngineDatabase._(this._db, this.uuid, this.schemaVersion);

  /// Opens `m.db` at [databasePath] and reads the `Information` row.
  ///
  /// Throws a [StateError] if the schema version is not 3.0.x (Engine DJ
  /// 4.x/5.x desktop databases).
  factory EngineDatabase.open(String databasePath, {bool readOnly = false}) {
    if (!File(databasePath).existsSync()) {
      throw StateError('Engine database not found at $databasePath');
    }

    final db = sqlite.sqlite3.open(
      databasePath,
      mode: readOnly
          ? sqlite.OpenMode.readOnly
          : sqlite.OpenMode.readWriteCreate,
    );

    try {
      db.execute('PRAGMA foreign_keys = ON');
      final info = db.select(
        'SELECT uuid, schemaVersionMajor, schemaVersionMinor, '
        'schemaVersionPatch FROM Information LIMIT 1',
      );
      if (info.isEmpty) {
        throw StateError('Engine database has no Information row');
      }
      final row = info.first;
      final version = (
        row['schemaVersionMajor'] as int,
        row['schemaVersionMinor'] as int,
        row['schemaVersionPatch'] as int,
      );
      if (version.$1 != 3 || version.$2 != 0) {
        throw StateError(
          'Unsupported Engine database schema '
          '${version.$1}.${version.$2}.${version.$3}; '
          'only schema 3.0.x (Engine DJ 4.x/5.x) is supported',
        );
      }
      return EngineDatabase._(db, row['uuid'] as String, version);
    } catch (_) {
      db.dispose();
      rethrow;
    }
  }

  final sqlite.Database _db;

  /// The database UUID from the `Information` table.
  final String uuid;

  /// Schema version (major, minor, patch).
  final (int, int, int) schemaVersion;

  /// Engine DJ 5.0 (schema 3.0.2+) stores artwork externally and adds
  /// `albumArtSourceHash` on `Track`.
  bool get supportsExternalAlbumArt => schemaVersion.$3 >= 2;

  static const List<String> _syncedTrackColumns = [
    'length',
    'bpm',
    'year',
    'path',
    'filename',
    'bitrate',
    'bpmAnalyzed',
    'fileBytes',
    'title',
    'artist',
    'album',
    'genre',
    'comment',
    'label',
    'composer',
    'remixer',
    'key',
    'rating',
    'fileType',
    'dateAdded',
    'pdbImportKey',
    'isBeatGridLocked',
    'albumArtId',
  ];

  List<String> get _trackColumns => [
    ..._syncedTrackColumns,
    if (supportsExternalAlbumArt) 'albumArtSourceHash',
  ];

  void runInTransaction(void Function() action) {
    _db.execute('BEGIN');
    try {
      action();
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// All non-streaming tracks, with their performance-data blobs.
  List<EngineTrackRow> readTracks() {
    final result = _db.select(
      'SELECT t.id, t.${_trackColumns.join(', t.')}, '
      'p.trackData, p.beatData, p.quickCues, p.loops '
      'FROM Track t '
      'LEFT JOIN PerformanceData p ON p.trackId = t.id '
      'WHERE t.streamingSource IS NULL',
    );
    return [
      for (final row in result)
        EngineTrackRow(
          id: row['id'] as int,
          pdbImportKey: row['pdbImportKey'] as int?,
          path: row['path'] as String?,
          columns: {
            for (final column in _trackColumns) column: row[column],
          },
          trackData: row['trackData'] as Uint8List?,
          beatData: row['beatData'] as Uint8List?,
          quickCues: row['quickCues'] as Uint8List?,
          loops: row['loops'] as Uint8List?,
        ),
    ];
  }

  /// The desired `Track` column values for [record], matching
  /// [_syncedTrackColumns].
  static Map<String, Object?> trackColumnValues(
    EngineTrackRecord record, {
    required bool supportsExternalAlbumArt,
    bool syncArt = true,
  }) => {
    'length': record.lengthSeconds,
    'bpm': record.bpm,
    'year': record.year,
    'path': record.path,
    'filename': record.filename,
    'bitrate': record.bitrate,
    'bpmAnalyzed': record.bpmAnalyzed,
    'fileBytes': record.fileBytes,
    'title': record.title,
    'artist': record.artist,
    'album': record.album,
    'genre': record.genre,
    'comment': record.comment,
    'label': record.label,
    'composer': record.composer,
    'remixer': record.remixer,
    'key': record.key,
    'rating': record.rating,
    'fileType': record.fileType,
    'dateAdded': record.dateAddedUnix,
    'pdbImportKey': record.rekordboxId,
    'isBeatGridLocked': record.hasBeatGrid ? 1 : 0,
    if (syncArt) 'albumArtId': record.albumArtId,
    if (syncArt && supportsExternalAlbumArt)
      'albumArtSourceHash': record.artworkSourceHash,
  };

  List<EngineAlbumArtRow> readAlbumArtRows() {
    final result = _db.select('SELECT id, hash FROM AlbumArt');
    return [
      for (final row in result)
        EngineAlbumArtRow(
          id: row['id'] as int,
          hash: coerceEngineAlbumArtHash(row['hash']),
        ),
    ];
  }

  void ensureNoAlbumArtPlaceholder() {
    final existing = _db.select('SELECT id FROM AlbumArt WHERE id = ?', [
      engineNoAlbumArtId,
    ]);
    if (existing.isEmpty) {
      _db.execute(
        'INSERT INTO AlbumArt (id, hash, albumArt) VALUES (?, NULL, NULL)',
        [engineNoAlbumArtId],
      );
    }
  }

  int insertAlbumArt({required String hash, required Uint8List imageData}) {
    _db.execute(
      'INSERT INTO AlbumArt (hash, albumArt) VALUES (?, ?)',
      [hash, imageData],
    );
    return _db.lastInsertRowId;
  }

  /// Inserts a new track plus its performance data. Returns the new id.
  int insertTrack(EngineTrackRecord record, {bool syncArt = true}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final columns = trackColumnValues(
      record,
      supportsExternalAlbumArt: supportsExternalAlbumArt,
      syncArt: syncArt,
    );
    _db.execute(
      'INSERT INTO Track (${columns.keys.join(', ')}, '
      'playOrder, timeLastPlayed, isPlayed, isAnalyzed, dateCreated, '
      'isAvailable, isMetadataOfPackedTrackChanged, '
      'isPerfomanceDataOfPackedTrackChanged, isMetadataImported, '
      'streamingFlags, explicitLyrics, '
      'originDatabaseUuid, lastEditTime) '
      'VALUES (${List.filled(columns.length, '?').join(', ')}, '
      '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        ...columns.values,
        null, // playOrder
        null, // timeLastPlayed
        0, // isPlayed
        0, // isAnalyzed: let Engine generate waveforms itself.
        record.dateAddedUnix, // dateCreated
        1, // isAvailable
        0, // isMetadataOfPackedTrackChanged
        0, // isPerfomanceDataOfPackedTrackChanged (sic)
        1, // isMetadataImported
        0, // streamingFlags
        0, // explicitLyrics
        uuid, // originDatabaseUuid
        now, // lastEditTime
      ],
    );
    final trackId = _db.lastInsertRowId;

    // Tracks originating from this database reference themselves.
    _db.execute(
      'UPDATE Track SET originTrackId = ? WHERE id = ?',
      [trackId, trackId],
    );

    _upsertPerformanceData(trackId, record);
    return trackId;
  }

  /// Updates the synced columns and performance data of an existing track.
  void updateTrack(
    int trackId,
    EngineTrackRecord record, {
    bool syncArt = true,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final columns = trackColumnValues(
      record,
      supportsExternalAlbumArt: supportsExternalAlbumArt,
      syncArt: syncArt,
    );
    _db.execute(
      'UPDATE Track SET '
      '${columns.keys.map((c) => '$c = ?').join(', ')}, '
      'lastEditTime = ? WHERE id = ?',
      [...columns.values, now, trackId],
    );
    _upsertPerformanceData(trackId, record);
  }

  void _upsertPerformanceData(int trackId, EngineTrackRecord record) {
    _db.execute(
      'INSERT INTO PerformanceData '
      '(trackId, trackData, beatData, quickCues, loops) '
      'VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT(trackId) DO UPDATE SET '
      'trackData = excluded.trackData, beatData = excluded.beatData, '
      'quickCues = excluded.quickCues, loops = excluded.loops',
      [
        trackId,
        record.trackData,
        record.beatData,
        record.quickCues,
        record.loops,
      ],
    );
  }

  void deleteTrack(int trackId) {
    _db.execute('DELETE FROM Track WHERE id = ?', [trackId]);
  }

  /// Deletes all root playlists; database triggers cascade to children and
  /// foreign keys cascade to playlist entities.
  void deleteAllPlaylists() {
    _db.execute('DELETE FROM Playlist WHERE parentListId = 0');
  }

  /// The id of the playlist titled [title] under [parentListId], if any.
  int? findPlaylist({required String title, required int parentListId}) {
    final result = _db.select(
      'SELECT id FROM Playlist WHERE title = ? AND parentListId = ?',
      [title, parentListId],
    );
    return result.isEmpty ? null : result.first['id'] as int;
  }

  /// Appends a playlist under [parentListId] (0 = root). Inserting with
  /// `nextListId = 0` appends at the end of the sibling list; the database's
  /// insert triggers re-wire the linked list. Returns the new id.
  int insertPlaylist({required String title, required int parentListId}) {
    final now = DateTime.now();
    _db.execute(
      'INSERT INTO Playlist (title, parentListId, isPersisted, nextListId, '
      'lastEditTime, isExplicitlyExported) VALUES (?, ?, 1, 0, ?, 1)',
      [title, parentListId, _formatEngineDateTime(now)],
    );
    return _db.lastInsertRowId;
  }

  /// Replaces the entities of playlist [listId] with [trackIds], in order.
  ///
  /// `PlaylistEntity` rows form a linked list via `nextEntityId`; each newly
  /// appended row becomes the tail and the previous tail is re-pointed.
  void replacePlaylistEntities(int listId, List<int> trackIds) {
    _db.execute('DELETE FROM PlaylistEntity WHERE listId = ?', [listId]);
    int? previousEntityId;
    for (final trackId in trackIds) {
      _db.execute(
        'INSERT INTO PlaylistEntity '
        '(listId, trackId, databaseUuid, nextEntityId, membershipReference) '
        'VALUES (?, ?, ?, 0, 0)',
        [listId, trackId, uuid],
      );
      final entityId = _db.lastInsertRowId;
      if (previousEntityId != null) {
        _db.execute(
          'UPDATE PlaylistEntity SET nextEntityId = ? WHERE id = ?',
          [entityId, previousEntityId],
        );
      }
      previousEntityId = entityId;
    }
  }

  void close() => _db.dispose();
}

/// Formats a timestamp the way Engine stores playlist `lastEditTime`
/// (`yyyy-MM-dd HH:mm:ss`).
String _formatEngineDateTime(DateTime time) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${time.year}-${pad(time.month)}-${pad(time.day)} '
      '${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}';
}

/// Normalizes `AlbumArt.hash` from Engine's sqlite row.
///
/// The column is declared TEXT, but some rows store a raw 20-byte SHA-1 BLOB
/// (legacy / third-party imports). Dart's sqlite3 driver returns those as
/// [Uint8List], which must be hex-encoded to match our digests.
@visibleForTesting
String? coerceEngineAlbumArtHash(Object? value) {
  switch (value) {
    case null:
      return null;
    case final String s:
      return s.isEmpty ? null : s;
    case final Uint8List bytes when bytes.isEmpty:
      return null;
    case final Uint8List bytes when bytes.length == 20:
      return Digest(bytes).toString();
    case final Uint8List bytes:
      return utf8.decode(bytes);
    default:
      throw ArgumentError.value(
        value,
        'value',
        'Unexpected AlbumArt.hash type: ${value.runtimeType}',
      );
  }
}
