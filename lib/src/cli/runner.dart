import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart' hide Env;
import 'package:io/io.dart';
import 'package:rkdb_dart/src/cli/cli.dart';
import 'package:rkdb_dart/src/logger/logger.dart';
import 'package:rkdb_dart/src/misc/misc.dart';

/// Creates the `CommandRunner` for rkdb_dart.
CommandRunner<int> createRkdbCommandRunner({
  IOSink? output,
  IOSink? error,
}) {
  final runner =
      CommandRunner<int>(
          'rkdb',
          'A command-line interface for Rekordbox database utilities.',
        )
        ..addCommand(CrawlCommand())
        ..addCommand(LoginCommand())
        ..addCommand(SyncCommand());

  runner.argParser
    ..addFlag(
      'version',
      abbr: 'v',
      help: 'Print the CLI version and exit.',
      negatable: false,
    )
    ..addVerboseFlag();

  runner.commands.forEach(
    (key, command) => command..argParser.addVerboseFlag(),
  );

  return runner;
}

/// Runs the CLI with the provided [arguments].
Future<int> runRkdbCli(List<String> arguments) async {
  final runner = createRkdbCommandRunner();

  try {
    log.debugMode = arguments.contains('--verbose');

    final argResults = runner.argParser.parse(arguments);
    if (argResults['version'] == true) {
      log.info('${Constants.appName} ${Constants.version}');
      return ExitCode.success.code;
    }

    return runWithCliDependencies<int?>(
      () async {
        try {
          return runner.run(arguments);
        } catch (e) {
          printerr(e);
          return ExitCode.software.code;
        }
      },
    ).then((exitCode) => exitCode ?? ExitCode.success.code);
  } on UsageException catch (e) {
    printerr(e.message);
    printerr(e.usage);
    return ExitCode.usage.code;
  } catch (e) {
    printerr('Unexpected error: $e');
    return ExitCode.software.code;
  }
}
