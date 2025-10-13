import 'dart:io';

import 'package:rkdb_dart/src/database/database.dart';
import 'package:rkdb_dart/src/misc/misc.dart';

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
  final file = dbFile ?? File('${Constants.appDataDir.path}/cache.db');

  final database = AppDatabase.fromFile(file);

  // Initialize metadata if needed
  await database.transaction(() async {
    await database.metadataDao.initializeMetadata();
  });

  return database;
}
