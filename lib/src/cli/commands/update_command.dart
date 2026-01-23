import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';
import 'package:pub_updater/pub_updater.dart';

class UpdateCommand extends Command<int> {
  UpdateCommand({PubUpdater? pubUpdater})
    : _pubUpdater = pubUpdater ?? PubUpdater();

  final PubUpdater _pubUpdater;

  @override
  final String name = 'update';

  @override
  final String description = 'Updates InPhase to the latest version.';

  @override
  Future<int> run() async {
    log.info('Checking for updates...');
    late final String latestVersion;
    try {
      latestVersion = await _pubUpdater.getLatestVersion(Constants.packageName);
    } catch (error) {
      log.error('Failed to check for updates: $error');
      return ExitCode.software.code;
    }

    final isUpToDate = Constants.version == latestVersion;
    if (isUpToDate) {
      log.info(
        '${green('✔︎')} InPhase is already at the latest version '
        '(${blue(Constants.version)}).',
      );
      return ExitCode.success.code;
    }

    log.info(
      'New version available: ${blue(latestVersion)} '
      '(current: ${Constants.version})',
    );
    log.info('Updating InPhase...');

    late ProcessResult result;
    try {
      result = await _pubUpdater.update(
        packageName: Constants.packageName,
        versionConstraint: latestVersion,
      );
    } catch (error) {
      log.error('Failed to update InPhase: $error');
      return ExitCode.software.code;
    }

    if (result.exitCode != ExitCode.success.code) {
      log.error('Error updating InPhase: ${result.stderr}');
      return ExitCode.software.code;
    }

    log.info(
      '${green('✔︎')} Successfully updated InPhase to ${blue(latestVersion)}',
    );

    return ExitCode.success.code;
  }
}
