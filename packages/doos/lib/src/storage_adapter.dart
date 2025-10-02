import 'package:doos/doos.dart';

/// {@template doos_storage_adapter}
/// A mixin for storage adapters.
///
/// Storage adapters are used to abstract the underlying storage implementation.
///
/// A working example is [DoosJsonStorageAdapter], which stores data in a JSON
/// file on the file system.
///
/// While any methods on a [Doos] are not allowed to throw, storage adapter
/// methods are allowed to do so when an error occurs.
/// {@endtemplate}
mixin DoosStorageAdapter {
  /// Writes the given [value] to the given [key].
  Future<void> write({required String key, required String value});

  /// Reads the value associated with the given [key].
  Future<String?> read({required String key});

  /// Deletes the value associated with the given [key].
  Future<void> delete({required String key});

  /// Deletes all values from the storage.
  Future<void> clear();
}
