import 'package:args/command_runner.dart';
import 'package:in_phase/src/cli/commands/library/library_sync_engine_command.dart';

class LibrarySyncCommand extends Command<int> {
  LibrarySyncCommand() {
    addSubcommand(LibrarySyncEngineCommand());
  }

  @override
  final String name = 'sync';

  @override
  final String description =
      'Syncs the Rekordbox library to another DJ platform.';
}
