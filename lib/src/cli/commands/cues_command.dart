import 'package:args/command_runner.dart';
import 'package:in_phase/src/cli/commands/cues/cues_sync_command.dart';

class CuesCommand extends Command<int> {
  CuesCommand() {
    addSubcommand(CuesSyncCommand());
  }

  @override
  final String name = 'cues';

  @override
  final String description = 'Manages cues in Rekordbox tracks.';
}
