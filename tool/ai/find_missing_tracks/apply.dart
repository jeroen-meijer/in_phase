import 'dart:io';

import 'package:args/args.dart';

import 'lib.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'cleanup',
      abbr: 'c',
      help:
          'Remove review artifacts after applying '
          '(keeps approved_mappings.json).',
      negatable: false,
    )
    ..addFlag(
      'dry-run',
      help: 'Validate mappings without writing to cache.db.',
      negatable: false,
    );

  final results = parser.parse(args);
  if (results.rest.isNotEmpty) {
    stderr
      ..writeln('Unexpected arguments: ${results.rest.join(' ')}')
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final doc = await readApprovedMappings();
  final mappings = parseMappingEntries(doc);

  final rbIds = await loadRekordboxTrackIds();
  final invalid = <String, String>{};
  for (final entry in mappings.entries) {
    if (!rbIds.contains(entry.value)) {
      invalid[entry.key] = entry.value;
    }
  }

  if (invalid.isNotEmpty) {
    stderr.writeln('Invalid Rekordbox track IDs:');
    for (final entry in invalid.entries) {
      stderr.writeln('  ${entry.key} -> ${entry.value}');
    }
    exitCode = 1;
    return;
  }

  if (results['dry-run'] as bool) {
    stdout.writeln('Dry run OK: ${mappings.length} mapping(s) validated.');
    for (final entry in mappings.entries) {
      stdout.writeln('  ${entry.key} -> ${entry.value}');
    }
    return;
  }

  await applyMappingsToCache(mappings);
  stdout.writeln('Applied ${mappings.length} mapping(s) to cache.db');

  if (results['cleanup'] as bool) {
    await cleanupReviewArtifacts();
    stdout.writeln('Cleaned up review artifacts.');
  }
}
