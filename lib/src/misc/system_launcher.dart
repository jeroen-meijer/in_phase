import 'dart:io';

/// Utility helpers for opening paths or URLs using the system launcher.
class SystemLauncher {
  /// Opens a local path (file or directory) using the default app.
  static Future<void> openPath(String path) async {
    await _runOpenCommand(path);
  }

  /// Opens a URL using the default browser/app.
  static Future<void> openUrl(String url) async {
    await _runOpenCommand(url);
  }

  static Future<void> _runOpenCommand(String target) async {
    final command = _commandForCurrentPlatform(target);
    final result = await Process.run(command.first, command.sublist(1));
    if (result.exitCode != 0) {
      throw ProcessException(
        command.first,
        command.sublist(1),
        'Failed to open "$target": ${result.stderr}',
        result.exitCode,
      );
    }
  }

  static List<String> _commandForCurrentPlatform(String target) {
    if (Platform.isMacOS) {
      return ['open', target];
    }
    if (Platform.isLinux) {
      return ['xdg-open', target];
    }
    if (Platform.isWindows) {
      return ['explorer', target];
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
