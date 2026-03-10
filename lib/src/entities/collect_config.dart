import 'dart:io';

import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'collect_config.g.dart';

/// Main configuration for the collect command.
///
/// NOTE(jeroen-meijer): The YAML parser automatically resolves anchors
/// (e.g., *playlist_id) during parsing, so we receive the actual values
/// and don't need to handle reference resolution.
@JsonSerializable(fieldRename: FieldRename.snake)
class CollectConfig {
  const CollectConfig({
    required this.collections,
  });

  const CollectConfig.empty() : this(collections: const []);

  factory CollectConfig.fromJson(Map<String, dynamic> json) =>
      _$CollectConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CollectConfigToJson(this);

  static Future<CollectConfig> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const config = CollectConfig.empty();
        await config.write(file);
        return config;
      } else {
        throw Exception('Collect config file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    final yaml = yamlDecode(content) as YamlMap;
    return CollectConfig.fromJson(yaml.toMap());
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

  final List<CollectCollection> collections;
}

/// A single collection configuration.
@JsonSerializable(fieldRename: FieldRename.snake)
class CollectCollection {
  const CollectCollection({
    required this.name,
    required this.target,
    required this.sources,
    this.options,
  });

  factory CollectCollection.fromJson(Map<String, dynamic> json) =>
      _$CollectCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectCollectionToJson(this);

  /// Unique identifier for the collection (used in logs and reports).
  final String name;

  /// Target playlist identifier (ID, URI, share URL, or exact name).
  /// Must exist and be writable.
  final String target;

  /// List of source playlist identifiers (IDs, URIs, URLs, exact names, glob patterns).
  final List<String> sources;

  /// Processing options for the collection.
  @JsonKey(includeIfNull: false)
  final CollectOptions? options;
}

/// Processing options for the collection.
@JsonSerializable(fieldRename: FieldRename.snake)
class CollectOptions {
  const CollectOptions({
    this.deduplicate,
  });

  factory CollectOptions.fromJson(Map<String, dynamic> json) =>
      _$CollectOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CollectOptionsToJson(this);

  /// Deduplication mode.
  /// Defaults to `on_id` if not specified.
  @JsonKey(includeIfNull: false)
  final DeduplicateMode? deduplicate;
}
