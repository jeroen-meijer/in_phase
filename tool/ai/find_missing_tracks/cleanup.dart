import 'dart:io';

import 'package:args/args.dart';

import 'lib.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'all',
      help: 'Also delete approved_mappings.json.',
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

  await cleanupReviewArtifacts(keepApproved: !(results['all'] as bool));
  stdout.writeln('Review artifacts cleaned up.');
}
