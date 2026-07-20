import 'package:args/command_runner.dart';
import 'package:in_phase/src/cli/commands/library/library.dart';

class LibraryCommand extends Command<int> {
  LibraryCommand() {
    addSubcommand(LibrarySyncCommand());
    addSubcommand(LibraryDoctorCommand());
  }

  @override
  final String name = 'library';

  @override
  final String description =
      'Manages syncing the Rekordbox library to other DJ platforms.';
}
