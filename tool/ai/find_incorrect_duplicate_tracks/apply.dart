import 'dart:io';

import 'lib.dart';

Future<void> main(List<String> args) async {
  final parser = buildApplyParser();
  final results = parser.parse(args);
  if (results.rest.isNotEmpty) {
    stderr
      ..writeln('Unexpected arguments: ${results.rest.join(' ')}')
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final doc = await readApprovedFixes();
  final approved = parseApprovedFixes(doc);

  final rbIds = await loadRekordboxTrackIds();
  final invalid = <String, String>{};
  for (final entry in approved.remap.entries) {
    if (!rbIds.contains(entry.value)) {
      invalid[entry.key] = entry.value;
    }
  }

  if (invalid.isNotEmpty) {
    stderr.writeln('Invalid Rekordbox track IDs in approved_fixes.json:');
    for (final entry in invalid.entries) {
      stderr.writeln('  ${entry.key} -> ${entry.value}');
    }
    exitCode = 1;
    return;
  }

  if (results['dry-run'] as bool) {
    stdout.writeln(
      'Dry run OK: remap=${approved.remap.length} '
      'delete=${approved.delete.length}',
    );
    for (final entry in approved.remap.entries) {
      stdout.writeln('  remap ${entry.key} -> ${entry.value}');
    }
    for (final id in approved.delete) {
      stdout.writeln('  delete $id');
    }
    return;
  }

  await applyFixesToCache(remap: approved.remap, delete: approved.delete);
  stdout.writeln(
    'Applied fixes: remap=${approved.remap.length} '
    'delete=${approved.delete.length}',
  );

  if (results['cleanup'] as bool) {
    await cleanupReviewArtifacts();
    stdout.writeln('Cleaned up review artifacts.');
  }
}
