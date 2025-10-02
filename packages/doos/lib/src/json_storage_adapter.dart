import 'dart:convert';
import 'dart:io';

import 'package:doos/src/storage_adapter.dart';
import 'package:meta/meta.dart';

/// {@template doos_json_storage_adapter}
/// A storage adapter that stores data in a JSON file and keeps an in-memory
/// cache of the data.
///
/// Use [create] to create a new instance.
/// {@endtemplate}
class DoosJsonStorageAdapter implements DoosStorageAdapter {
  /// {@macro doos_json_storage_adapter}
  const DoosJsonStorageAdapter._({
    required File file,
    required Map<String, String> initialData,
  }) : _file = file,
       _data = initialData;

  final File _file;
  final Map<String, String> _data;

  /// Creates a new [DoosJsonStorageAdapter] instance.
  ///
  /// If [createFileIfNotExists] is true, the file will be created if it does
  /// not exist, otherwise a [FileNotFoundException] will be thrown.
  ///
  /// If [clearFileOnReadError] is true, the file will be cleared if an error
  /// occurs while reading it, otherwise a [JsonDecodeError] will be thrown.
  static Future<DoosJsonStorageAdapter> create({
    required File file,
    bool createFileIfNotExists = true,
    bool clearFileOnReadError = false,
  }) async {
    if (!file.existsSync()) {
      if (!createFileIfNotExists) {
        throw FileNotFoundException(file);
      }

      file.createSync(recursive: true);
      return DoosJsonStorageAdapter._(file: file, initialData: {});
    }

    dynamic initialData;
    try {
      initialData = jsonDecode(file.readAsStringSync());
    } catch (e) {
      if (clearFileOnReadError) {
        file.writeAsStringSync('{}');
        return DoosJsonStorageAdapter._(file: file, initialData: {});
      }

      throw JsonDecodeError(file, e);
    }

    try {
      initialData = Map<String, String>.from(initialData as Map);
    } catch (e) {
      if (clearFileOnReadError) {
        file.writeAsStringSync('{}');
        return DoosJsonStorageAdapter._(file: file, initialData: {});
      }

      throw JsonDecodeError(file, e);
    }

    return DoosJsonStorageAdapter._(
      file: file,
      initialData: initialData as Map<String, String>,
    );
  }

  @override
  Future<void> clear() async {
    _data.clear();
    await _write();
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
    await _write();
  }

  @override
  Future<String?> read({required String key}) async {
    return _data[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
    await _write();
  }

  Future<void> _write() async {
    await _file.writeAsString(jsonEncode(_data));
  }
}

/// {@template doos_json_storage_adapter_error}
/// Base class for errors that occur during JSON storage adapter operations.
/// {@endtemplate}
sealed class DoosJsonStorageAdapterError implements Exception {
  /// {@macro doos_json_storage_adapter_error}
  const DoosJsonStorageAdapterError();

  @override
  @mustBeOverridden
  String toString();
}

/// {@template file_not_found_exception}
/// Exception thrown when a file provided to [DoosJsonStorageAdapter.create] is
/// not found.
/// {@endtemplate}
class FileNotFoundException extends DoosJsonStorageAdapterError {
  /// {@macro file_not_found_exception}
  const FileNotFoundException(this.file);

  /// The file that was not found.
  final File file;

  @override
  String toString() => '$FileNotFoundException($file)';
}

/// {@template json_decode_error}
/// Exception thrown when a JSON string cannot be decoded.
/// {@endtemplate}
class JsonDecodeError extends DoosJsonStorageAdapterError {
  /// {@macro json_decode_error}
  const JsonDecodeError(this.file, this.error);

  /// The file that was read.
  final File file;

  /// The error that occurred.
  final Object error;

  @override
  String toString() => '$JsonDecodeError($file, $error)';
}
