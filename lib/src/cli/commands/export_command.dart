import 'package:args/command_runner.dart';
import 'package:in_phase/src/cli/commands/export/export_spicetify_command.dart';

class ExportCommand extends Command<int> {
  ExportCommand() {
    addSubcommand(ExportSpicetifyCommand());
  }

  @override
  final String name = 'export';

  @override
  final String description = 'Exports data for companion tools.';
}
