import 'package:args/command_runner.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';

class CacheCleanCommand extends Command<int> {
  CacheCleanCommand();

  @override
  final String name = 'clean';

  @override
  final String description =
      'Deletes the build folder that includes sync and crawl reports.';

  @override
  Future<int> run() async {
    final buildDir = Constants.buildDir;

    // Check if directory exists
    if (!buildDir.existsSync()) {
      log.info('Build directory does not exist: ${buildDir.path}');
      return ExitCode.success.code;
    }

    try {
      log.info('Deleting build directory: ${buildDir.path}');
      await buildDir.delete(recursive: true);
      log.info('Build directory deleted successfully');
      return ExitCode.success.code;
    } catch (e) {
      log.error('Error deleting build directory: $e');
      return ExitCode.software.code;
    }
  }
}
