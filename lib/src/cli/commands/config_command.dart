import 'package:args/command_runner.dart';
import 'package:in_phase/src/cli/commands/config/config_reveal_command.dart';

class ConfigCommand extends Command<int> {
  ConfigCommand() {
    addSubcommand(ConfigRevealCommand());
  }

  @override
  final String name = 'config';

  @override
  final String description = 'Manages the config directory.';
}
