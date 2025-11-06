import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';

class LoginCommand extends Command<int> {
  LoginCommand() {
    argParser.addFlag(
      'force',
      help: 'Remove cached credentials and log in again.',
      negatable: false,
    );
  }

  @override
  final String name = 'login';

  @override
  final String description = 'Logs in to Spotify. Useful for other commands.';

  @override
  Future<int> run() async {
    final isForceModeEnabled = argResults!['force'] == true;

    final api = await spotifyLogin(useCache: !isForceModeEnabled);
    final me = await api.me.get();
    log.info('${green('✔︎')} Logged in to Spotify as ${blue(me.displayName!)}');

    return ExitCode.success.code;
  }
}
