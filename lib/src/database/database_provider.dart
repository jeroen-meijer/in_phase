import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';

/// Gets the database instance from the current zone.
///
/// Usage:
/// ```dart
/// final album = await db().albumsDao.getAlbum(albumId);
/// ```
AppDatabase db() => Zonable.fromZone<AppDatabase>();
