import 'package:meta/meta.dart';

/// {@template doos_storage_read_error}
/// Base class for errors that occur during read operations.
/// {@endtemplate}
sealed class DoosStorageReadError implements Exception {
  /// {@macro storage_read_error}
  const DoosStorageReadError(this.message);

  /// The error message.
  final String message;

  @override
  @mustBeOverridden
  String toString();
}

/// {@template doos_storage_write_error}
/// Base class for errors that occur during write operations.
/// {@endtemplate}
sealed class DoosStorageWriteError implements Exception {
  /// {@macro storage_write_error}
  const DoosStorageWriteError(this.message);

  /// The error message.
  final String message;

  @override
  @mustBeOverridden
  String toString();
}

/// {@template doos_storage_remove_error}
/// Base class for errors that occur during remove operations.
/// {@endtemplate}
sealed class DoosStorageRemoveError implements Exception {
  /// {@macro storage_remove_error}
  const DoosStorageRemoveError(this.message);

  /// The error message.
  final String message;

  @override
  @mustBeOverridden
  String toString();
}

/// {@template doos_storage_not_found_error}
/// Error when a key does not exist in storage.
/// {@endtemplate}
final class DoosStorageNotFoundError extends DoosStorageReadError {
  /// {@macro storage_not_found_error}
  const DoosStorageNotFoundError(String key)
    : super('Key "$key" not found in storage');

  @override
  String toString() => '$DoosStorageNotFoundError($message)';
}

/// {@template doos_storage_type_error}
/// Error when the stored type does not match the expected type.
/// {@endtemplate}
final class DoosStorageTypeError extends DoosStorageReadError {
  /// {@macro storage_type_error}
  const DoosStorageTypeError({
    required String key,
    required String expectedType,
    required String actualType,
  }) : super(
         'Type mismatch for key "$key": '
         'expected $expectedType, got $actualType',
       );

  @override
  String toString() => '$DoosStorageTypeError($message)';
}

/// {@template doos_storage_deserialization_error}
/// Error when stored data cannot be deserialized to the expected type.
/// {@endtemplate}
final class DoosStorageDeserializationError extends DoosStorageReadError {
  /// {@macro storage_deserialization_error}
  const DoosStorageDeserializationError({
    required String key,
    required String type,
    Object? originalError,
  }) : super(
         'Failed to deserialize "$key" to '
         '$type${originalError != null ? ': $originalError' : ''}',
       );

  @override
  String toString() => '$DoosStorageDeserializationError($message)';
}

/// {@template doos_storage_serialization_error}
/// Error when data cannot be serialized for storage.
/// {@endtemplate}
final class DoosStorageSerializationError extends DoosStorageWriteError {
  /// {@macro storage_serialization_error}
  const DoosStorageSerializationError({
    required String key,
    required String type,
    Object? originalError,
  }) : super(
         'Failed to serialize "$key" '
         'of type $type${originalError != null ? ': $originalError' : ''}',
       );

  @override
  String toString() => '$DoosStorageSerializationError($message)';
}

/// {@template doos_storage_read_unknown_error}
/// Error for unknown storage errors during read operations.
/// {@endtemplate}
final class DoosStorageReadUnknownError extends DoosStorageReadError {
  /// {@macro storage_read_unknown_error}
  const DoosStorageReadUnknownError([String? message])
    : super(message ?? 'Unknown storage error during read');

  @override
  String toString() => '$DoosStorageReadUnknownError($message)';
}

/// {@template doos_storage_write_unknown_error}
/// Error for unknown storage errors during write operations.
/// {@endtemplate}
final class DoosStorageWriteUnknownError extends DoosStorageWriteError {
  /// {@macro storage_write_unknown_error}
  const DoosStorageWriteUnknownError([String? message])
    : super(message ?? 'Unknown storage error during write');

  @override
  String toString() => '$DoosStorageWriteUnknownError($message)';
}

/// {@template doos_storage_remove_unknown_error}
/// Error for unknown storage errors during remove operations.
/// {@endtemplate}
final class DoosStorageRemoveUnknownError extends DoosStorageRemoveError {
  /// {@macro storage_remove_unknown_error}
  const DoosStorageRemoveUnknownError([String? message])
    : super(message ?? 'Unknown storage error during remove');

  @override
  String toString() => '$DoosStorageRemoveUnknownError($message)';
}
