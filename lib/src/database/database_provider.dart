import 'dart:io';

import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';

/// Gets the database instance from the current zone.
///
/// Usage:
/// ```dart
/// final album = await db().albumsDao.getAlbum(albumId);
/// ```
AppDatabase db() => Zonable.fromZone<AppDatabase>();

/// Creates a new database instance.
///
/// Call this once and inject it into the zone using Zonable.inject().
Future<AppDatabase> createDatabase({File? dbFile}) async {
  final database = dbFile != null
      ? AppDatabase.fromFile(dbFile)
      : AppDatabase.fromCacheDbFile();

  // Initialize metadata if needed
  await database.transaction(() async {
    await database.metadataDao.initializeMetadata();
  });

  return database;
}
