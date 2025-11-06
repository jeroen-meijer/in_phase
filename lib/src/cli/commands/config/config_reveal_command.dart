import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';

class ConfigRevealCommand extends Command<int> {
  ConfigRevealCommand();

  @override
  final String name = 'reveal';

  @override
  final String description = 'Opens the config directory in the file manager.';

  @override
  Future<int> run() async {
    final configDir = Constants.appDataDir.path;

    // Check if directory exists
    final dir = Directory(configDir);
    if (!dir.existsSync()) {
      log.error('Config directory does not exist: $configDir');
      return ExitCode.noInput.code;
    }

    // Determine platform-specific command
    final List<String> command;
    if (Platform.isMacOS) {
      command = ['open', configDir];
    } else if (Platform.isLinux) {
      command = ['xdg-open', configDir];
    } else if (Platform.isWindows) {
      command = ['explorer', configDir];
    } else {
      log.error(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
      return ExitCode.unavailable.code;
    }

    try {
      log.info('Opening config directory: $configDir');
      final result = await Process.run(
        command[0],
        command.sublist(1),
      );

      if (result.exitCode != 0) {
        log.error(
          'Failed to open directory: ${result.stderr}',
        );
        return ExitCode.software.code;
      }

      return ExitCode.success.code;
    } catch (e) {
      log.error('Error opening directory: $e');
      return ExitCode.software.code;
    }
  }
}
