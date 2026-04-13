import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Copies [text] to the system clipboard when supported.
///
/// Returns whether the copy succeeded (best effort per platform).
Future<bool> copyTextToClipboard(String text) async {
  if (Platform.isMacOS) {
    return _copyViaStdinUtf8(['pbcopy'], text);
  }
  if (Platform.isLinux) {
    if (Platform.environment.containsKey('WAYLAND_DISPLAY')) {
      if (await _copyViaStdinUtf8(['wl-copy'], text)) return true;
    }
    if (await _copyViaStdinUtf8(['xclip', '-selection', 'clipboard'], text)) {
      return true;
    }
    return _copyViaStdinUtf8(['xsel', '--clipboard', '--input'], text);
  }
  if (Platform.isWindows) {
    return _copyWindowsClip(text);
  }
  return false;
}

Future<bool> _copyViaStdinUtf8(List<String> command, String text) async {
  try {
    final process = await Process.start(
      command.first,
      command.sublist(1),
    );
    process.stdin.add(utf8.encode(text));
    await process.stdin.close();
    return await process.exitCode == 0;
  } on Object {
    return false;
  }
}

Future<bool> _copyWindowsClip(String text) async {
  try {
    final process = await Process.start('clip', []);
    final buffer = Uint8List(text.length * 2);
    final byteData = ByteData.sublistView(buffer);
    for (var i = 0; i < text.length; i++) {
      byteData.setUint16(i * 2, text.codeUnitAt(i), Endian.little);
    }
    process.stdin.add(buffer);
    await process.stdin.close();
    return await process.exitCode == 0;
  } on Object {
    return false;
  }
}
