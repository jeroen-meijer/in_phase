import 'dart:io';

/// Process names used by Engine DJ desktop across versions.
const List<String> _engineProcessNames = ['Engine DJ', 'Engine Prime'];

/// Checks whether Engine DJ (or the older Engine Prime) is running.
Future<bool> checkIsEngineDjRunning() async {
  if (Platform.isWindows) {
    for (final name in _engineProcessNames) {
      final res = await Process.run('tasklist', [
        '/FI',
        'IMAGENAME eq $name.exe',
        '/NH',
      ]);
      if (res.exitCode != 0) continue;
      final out = (res.stdout as Object?).toString().toLowerCase();
      if (out.contains('${name.toLowerCase()}.exe')) return true;
    }
    return false;
  }

  for (final name in _engineProcessNames) {
    final res = await Process.run('pgrep', ['-x', name]);
    if (res.exitCode == 0) return true;
  }
  return false;
}
