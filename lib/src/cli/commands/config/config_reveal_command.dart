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

    try {
      log.info('Opening config directory: $configDir');
      await SystemLauncher.openPath(configDir);
      return ExitCode.success.code;
    } catch (e) {
      if (e is UnsupportedError) {
        log.error(e.message);
        return ExitCode.unavailable.code;
      }
      log.error('Error opening directory: $e');
      return ExitCode.software.code;
    }
  }
}
