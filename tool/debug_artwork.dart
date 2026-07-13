import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';

Future<void> main() async {
  final config = getMostRecentRekordboxConfig()!;
  final share = p.join(config.dbDir, 'share');
  final db = await RekordboxDatabase.connect();

  for (final title in ['Get Funky - Final Mix & Master', 'Bad Boy Horns']) {
    final content = await (db.select(db.djmdContent)
          ..where((c) => c.title.equals(title)))
        .getSingleOrNull();
    if (content == null) continue;

    final album = content.albumID == null
        ? null
        : await (db.select(db.djmdAlbum)
              ..where((a) => a.id.equals(content.albumID!)))
            .getSingleOrNull();

    print('\n=== $title ===');
    print('content.imagePath: ${content.imagePath}');
    print('album.imagePath: ${album?.imagePath}');

    for (final rel in [content.imagePath, album?.imagePath]) {
      if (rel == null || rel.isEmpty) continue;
      final path = p.join(share, rel.replaceFirst(RegExp('^/'), ''));
      print('  resolved: $path exists=${await File(path).exists()}');
    }
  }

  await db.close();
}
