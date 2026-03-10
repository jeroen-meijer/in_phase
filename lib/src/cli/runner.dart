import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart' hide Env;
import 'package:in_phase/src/cli/cli.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';

/// Creates the `CommandRunner` for InPhase.
CommandRunner<int> createInPhaseCommandRunner({
  IOSink? output,
  IOSink? error,
}) {
  final runner =
      CommandRunner<int>(
          Constants.commandName,
          'A command-line interface for Rekordbox database utilities.',
        )
        ..addCommand(CacheCommand())
        ..addCommand(CollectCommand())
        ..addCommand(ConfigCommand())
        ..addCommand(CrawlCommand())
        ..addCommand(CurateCommand())
        ..addCommand(CuesCommand())
        ..addCommand(LoginCommand())
        ..addCommand(SearchCommand())
        ..addCommand(SyncCommand())
        ..addCommand(UpdateCommand());

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
Future<int> runInPhaseCli(List<String> arguments) async {
  final runner = createInPhaseCommandRunner();

  try {
    log.debugMode = arguments.contains('--verbose');

    // Ensure default config files exist before running any command
    await ensureDefaultConfigs();

    final argResults = runner.argParser.parse(arguments);
    if (argResults['version'] == true) {
      log.info('${Constants.appName} ${Constants.version}');
      return ExitCode.success.code;
    }

    final exitCode = await runWithCliDependencies<int?>(
      () async {
        try {
          return runner.run(arguments);
        } on UsageException {
          rethrow;
        } catch (e) {
          printerr(e);
          return ExitCode.software.code;
        }
      },
    );
    return exitCode ?? ExitCode.success.code;
  } on UsageException catch (e) {
    printerr(e.message);
    printerr(e.usage);
    return ExitCode.usage.code;
  } catch (e) {
    printerr('Unexpected error: $e');
    return ExitCode.software.code;
  }
}
