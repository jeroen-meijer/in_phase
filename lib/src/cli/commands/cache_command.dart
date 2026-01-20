import 'package:args/command_runner.dart';
import 'package:in_phase/src/cli/commands/cache/cache_clean_command.dart';

class CacheCommand extends Command<int> {
  CacheCommand() {
    addSubcommand(CacheCleanCommand());
  }

  @override
  final String name = 'cache';

  @override
  final String description = 'Manages the cache and build directories.';
}
