import 'dart:io';

import 'package:in_phase/src/misc/yaml_map_extensions.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

/// Reads [file] as a YAML config and builds it with [fromJson].
///
/// See [parseYamlConfig] for how the content is interpreted.
Future<T> readYamlConfig<T>(
  File file, {
  required T Function(Map<String, dynamic> json) fromJson,
  required T defaults,
}) async {
  if (!await file.exists()) {
    throw FileSystemException('Config file not found', file.path);
  }
  return parseYamlConfig(
    await file.readAsString(),
    fromJson: fromJson,
    defaults: defaults,
    source: file.path,
  );
}

/// Parses YAML [content] and builds a config with [fromJson].
///
/// An empty or comment-only document yields [defaults]. Throws a
/// [FormatException] when the root is not a map. [source] names the file in
/// that error.
T parseYamlConfig<T>(
  String content, {
  required T Function(Map<String, dynamic> json) fromJson,
  required T defaults,
  String? source,
}) {
  final decoded = yamlDecode(content);
  if (decoded == null) {
    return defaults;
  }
  if (decoded is! YamlMap) {
    throw FormatException(
      'Expected a YAML map at the root${source == null ? '' : ' of $source'}',
    );
  }
  return fromJson(decoded.toMap());
}
