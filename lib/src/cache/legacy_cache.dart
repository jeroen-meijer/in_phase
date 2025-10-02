import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

@Deprecated('Use Doos instead')
class Cache with MapBase<String, Object> {
  @Deprecated('Use Doos instead')
  const Cache(this._data);

  final Map<String, dynamic> _data;

  static const _cacheFileName = '.rkdb_cache';
  static File get _cacheFile => File(path.join(_getUserDir(), _cacheFileName));

  static String _getUserDir() {
    String? home;
    if (Platform.isMacOS) {
      home = Platform.environment['HOME'];
    } else if (Platform.isLinux) {
      home = Platform.environment['HOME'];
    } else if (Platform.isWindows) {
      home = Platform.environment['UserProfile'];
    }

    return home ??
        (throw UnsupportedError(
          'Unsupported platform or missing '
          'home environment variable: ${Platform.operatingSystem}',
        ));
  }

  static Future<Cache> initAndRead() async {
    final file = _cacheFile;
    if (!file.existsSync()) {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
    }

    final content = file.readAsStringSync();
    final json = Map<String, dynamic>.from(jsonDecode(content) as Map);
    return Cache(json);
  }

  T? getValue<T>(String key) {
    return _data[key] as T?;
  }

  Future<void> removeValue(String key) async {
    await setValue(key, null);
  }

  Future<void> setValue(String key, Object? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    await _write();
  }

  Future<void> _write() async {
    _cacheFile.writeAsStringSync(jsonEncode(_data));
  }

  @override
  Object? operator [](Object? key) {
    if (key is! String) {
      throw ArgumentError.value(key, 'key', 'Key must be a string');
    }
    return getValue<Object?>(key);
  }

  @override
  void operator []=(String key, Object? value) {
    setValue(key, value);
  }

  @override
  void clear() {
    _data.clear();
    _write();
  }

  @override
  Iterable<String> get keys => _data.keys;

  @override
  void remove(Object? key) {
    _data.remove(key);
    _write();
  }
}
