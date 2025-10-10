import 'dart:async';
import 'dart:convert';

import 'package:doos/doos.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// {@template doos}
/// An API for storing and retrieving data locally and securely.
/// {@endtemplate}
class Doos with Disposable {
  /// {@macro doos}
  Doos({required DoosStorageAdapter adapter}) : _adapter = adapter;

  /// The underlying storage implementation.
  final DoosStorageAdapter _adapter;

  final Map<String, _StorageEntryState> _entries = {};

  /// Gets or creates a BehaviorSubject for the given key and increments the
  /// listener count. Does not seed the subject with initial value - that
  /// happens when onChange() is first called.
  BehaviorSubject<Object?> _getOrCreateSubject(String key) {
    final entry = _entries[key];
    if (entry != null) {
      _entries[key] = entry.copyWith(listeners: entry.listeners + 1);
      return entry.subject;
    }

    final subject = BehaviorSubject<Object?>();
    _entries[key] = _StorageEntryState(
      listeners: 1,
      subject: subject,
      initialValueFetched: false,
      initialValueFetch: null,
    );

    return subject;
  }

  /// Decrements the listener count for the given key and disposes of the
  /// subject if there are no more listeners.
  Future<void> _decrementListenerCount(String key) async {
    final entry = _entries[key];
    if (entry == null) return;

    final newListeners = entry.listeners - 1;
    if (newListeners <= 0) {
      await entry.subject.close();
      _entries.remove(key);
    } else {
      _entries[key] = entry.copyWith(listeners: newListeners);
    }
  }

  /// Notify all listeners of a value change for the given key.
  void _notifyValueChanged(String key, Object? value) {
    final entry = _entries[key];
    if (entry?.subject != null && !entry!.subject.isClosed) {
      entry.subject.add(value);
    }
  }

  /// Notify all listeners of an error for the given key.
  void _notifyError(String key, Object error, StackTrace stackTrace) {
    final entry = _entries[key];
    if (entry?.subject != null && !entry!.subject.isClosed) {
      entry.subject.addError(error, stackTrace);
    }
  }

  /// Handle the onChange() method call for a specific key.
  Future<void> _handleOnChange(String key, bool fetchInitialValue) async {
    if (!fetchInitialValue) return;

    final entry = _entries[key];
    if (entry == null) return;

    if (entry.initialValueFetched) return;

    if (entry.initialValueFetch != null) {
      await entry.initialValueFetch;
      return;
    }

    final completer = Completer<void>();
    _entries[key] = entry.copyWith(initialValueFetch: completer.future);

    try {
      await _doInitialValueFetch(key);
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  }

  /// Actually perform the initial value fetch for the given key.
  Future<void> _doInitialValueFetch(String key) async {
    final entry = _entries[key];
    if (entry == null) return;

    final readResult = await read(key);
    switch (readResult) {
      case DoosOk(:final value):
        if (!entry.subject.isClosed) {
          entry.subject.add(value);
        }
      case DoosErr(:final error):
        if (!entry.subject.isClosed) {
          entry.subject.addError(error, StackTrace.current);
        }
    }

    _entries[key] = entry.copyWith(initialValueFetched: true);
  }

  @override
  Future<void> dispose() async {
    await Future.wait(_entries.values.map((e) => e.subject.close()));
    _entries.clear();
  }

  /// Deserializes the underlying storage value to a valid JSON value.
  ///
  /// Used by [read] and only exposed for testing purposes. Do not use it in
  /// production code.
  @visibleForTesting
  DoosResult<Object?, DoosStorageReadError> deserializeJson(
    String key,
    String value,
  ) {
    try {
      return DoosOk(json.decode(value));
    } on FormatException catch (e) {
      return DoosErr(
        DoosStorageDeserializationError(
          key: key,
          type: 'JSON',
          error: e,
        ),
      );
    }
  }

  /// Serializes the given value to a string that can be stored in the
  /// underlying storage.
  ///
  /// Used by [write] and only exposed for testing purposes. Do not use it in
  /// production code.
  @visibleForTesting
  DoosResult<String, DoosStorageWriteError> serialize<T>(String key, T value) {
    if (value == null) {
      return DoosErr(
        DoosStorageSerializationError(
          key: key,
          type: T.toString(),
          originalError: ArgumentError.value(
            value,
            'value',
            'Value cannot be null. '
                'See LocalStorage documentation for a list of supported types.',
          ),
        ),
      );
    }
    try {
      return DoosOk(json.encode(value));
      // ignore: avoid_catching_errors
    } on JsonUnsupportedObjectError catch (e) {
      return DoosErr(
        DoosStorageSerializationError(
          key: key,
          type: T.toString(),
          originalError: e,
        ),
      );
    }
  }

  /// The default `deserializer` used by [getEntry] that simply returns the
  /// value it is given after type-casting it to type `T?`.
  static T? _identity<T>(dynamic value) => value as T?;

  /// Internal key used for the [selfTest].
  ///
  /// Only exposed for testing purposes. Do not use it in production code.
  @visibleForTesting
  static const ({String key, String value}) selfTestData = (
    key: '_self_test',
    value: 'self_test_value',
  );

  /// Performs a comprehensive self-test to verify storage functionality.
  ///
  /// This method ensures that the underlying storage is accessible and ready
  /// for use. It performs a complete read/write/delete cycle to verify the
  /// storage connection.
  ///
  /// Returns `true` if the storage is working correctly. If any exception
  /// occurs, returns `false`. In such cases, consider resetting the storage by
  /// calling [clear].
  ///
  /// See also:
  /// - [clearIfCorrupted], which runs a [selfTest] and, if it returns `false`,
  ///   clears the storage silently using [clear].
  Future<bool> selfTest() async {
    try {
      await _adapter.write(key: selfTestData.key, value: selfTestData.value);
      final value = await _adapter.read(key: selfTestData.key);
      if (value != selfTestData.value) {
        return false;
      }
      await _adapter.delete(key: selfTestData.key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Irreversibly wipes all data from the storage.
  Future<void> clear() {
    return _adapter.clear();
  }

  /// Runs a [selfTest] and, if it returns `false` or throws an exception,
  /// clears the storage silently using [clear].
  Future<void> clearIfCorrupted() async {
    late final bool isWorking;
    try {
      isWorking = await selfTest();
    } catch (_) {
      isWorking = false;
    }

    if (!isWorking) {
      await clear();
    }
  }

  /// Returns the [DoosStorageEntry] associated with the given [key].
  ///
  /// ## About deserialization
  ///
  /// If `T` is a supported JSON type, no [deserializer] is needed, as the value
  /// will be automatically serialized and deserialized using the default JSON
  /// serializer. If `T` is not a supported JSON type, a [deserializer] must be
  /// provided to deserialize the value.
  ///
  /// If a [deserializer] is provided, it is given the value stored in the
  /// underlying storage **after** it has been deserialized using the default
  /// JSON deserializer. This means that the [deserializer] should expect a
  /// value of type `Object?` that is one of the supported types (or null) and
  /// return a value of type `T`.
  ///
  /// The following types are supported out of the box and do not need a
  /// [deserializer]:
  /// * `String`
  /// * `int`
  /// * `double`
  /// * `bool`
  /// * `List<dynamic>`
  /// * `Map<String, dynamic>`
  /// * `null`
  DoosStorageEntry<T> getEntry<T>(
    String key, {
    ValueDeserializer<T>? deserializer,
  }) {
    assert(T != dynamic, 'Type T must be specified.');

    final finalDeserializer = deserializer ?? _identity<T>;
    final subject = _getOrCreateSubject(key);

    return DoosStorageEntry<T>(
      key: key,
      getValue: () => read(key),
      setValue: (value) => write<T>(key, value),
      deserializer: finalDeserializer,
      onDispose: () => _decrementListenerCount(key),
      subject: subject,
      handleOnChange: _handleOnChange,
    );
  }

  /// Reads the value associated with the given [key] and returns it.
  ///
  /// Used by [DoosStorageEntry] to read the value associated with the entry.
  /// Only exposed for testing purposes. Do not use it in production code.
  @visibleForTesting
  Future<DoosResult<Object?, DoosStorageReadError>> read(String key) async {
    try {
      final value = await _adapter.read(key: key);
      if (value == null) {
        return const DoosOk(null);
      }

      return deserializeJson(key, value);
    } catch (error, stackTrace) {
      final storageError = DoosStorageReadUnknownError(
        'Failed to read key "$key": $error',
      );

      _notifyError(key, storageError, stackTrace);
      return DoosErr(storageError);
    }
  }

  /// Writes the given [value] to the given [key].
  ///
  /// Writing `null` is equivalent to removing the key.
  ///
  /// Used by [DoosStorageEntry] to write the value associated with the entry.
  /// Only exposed for testing purposes. Do not use it in production code.
  @visibleForTesting
  Future<DoosResult<void, DoosStorageWriteError>> write<T>(
    String key,
    T? value,
  ) {
    assert(T != dynamic, 'Type T must be specified.');

    return _performWrite<T>(key, value);
  }

  Future<DoosResult<void, DoosStorageWriteError>> _performWrite<T>(
    String key,
    T? value,
  ) async {
    try {
      if (value == null) {
        await _adapter.delete(key: key);
        _notifyValueChanged(key, null);
        return const DoosOk(null);
      }

      final serializeResult = serialize<T>(key, value);
      switch (serializeResult) {
        case DoosOk(value: final serializedValue):
          await _adapter.write(key: key, value: serializedValue);
          _notifyValueChanged(key, value);
          return const DoosOk(null);
        case DoosErr(:final error):
          _notifyError(key, error, StackTrace.current);
          return DoosErr(error);
      }
    } catch (error, stackTrace) {
      final storageError = DoosStorageWriteUnknownError(
        'Failed to write key "$key": $error',
      );

      _notifyError(key, storageError, stackTrace);
      return DoosErr(storageError);
    }
  }
}

/// A function that returns a value.
///
/// Used by [DoosStorageEntry] to read the value associated with the entry from
/// the [Doos] instance.
typedef ValueGetter =
    Future<DoosResult<Object?, DoosStorageReadError>> Function();

/// A function that writes a value.
///
/// Used by [DoosStorageEntry] to write the value associated with the entry to
/// the [Doos] instance.
typedef ValueSetter<T> =
    Future<DoosResult<void, DoosStorageWriteError>> Function(T? value);

/// A function that maps a dynamic type to a value of type `T`.
///
/// Used by [DoosStorageEntry] to deserialize non-JSON types.
typedef ValueDeserializer<T> = T? Function(Object value);

/// A function that handles onChange() calls.
///
/// Used by [DoosStorageEntry] to handle the onChange() method call.
// ignore: avoid_positional_boolean_parameters
typedef OnChangeHandler =
    // ignore: avoid_positional_boolean_parameters
    Future<void> Function(String key, bool fetchInitialValue);

/// {@template storage_entry}
/// Represents a key-value pair in the local storage.
///
/// Use methods such as [read], [readOrNull], [write], [writeIfAbsent], and
/// [remove] to interact with the local storage.
///
/// ## Note
///
/// There is no distinction between a key not found and a key with a `null`
/// value.
/// {@endtemplate}
class DoosStorageEntry<T> with EquatableMixin, Disposable {
  /// {@macro storage_entry}
  ///
  /// This constructor is only exposed for testing purposes. Do not use it in
  /// production code.
  ///
  /// To retrieve a [DoosStorageEntry] instance, use [Doos.getEntry].
  DoosStorageEntry({
    required this.key,
    required ValueGetter getValue,
    required ValueSetter<T> setValue,
    required ValueDeserializer<T> deserializer,
    required Future<void> Function() onDispose,
    required BehaviorSubject<Object?> subject,
    required OnChangeHandler handleOnChange,
  }) : _getValue = getValue,
       _setValue = setValue,
       _deserializer = deserializer,
       _onDispose = onDispose,
       _subject = subject,
       _handleOnChange = handleOnChange;

  /// The key associated with this entry.
  final String key;

  /// Internal method for reading the value associated with this entry.
  ///
  /// Provided by [Doos.getEntry] upon creation.
  final ValueGetter _getValue;

  /// Internal method for setting the value associated with this entry.
  ///
  /// Provided by [Doos.getEntry] upon creation.
  final ValueSetter<T> _setValue;

  /// Internal method for transforming the value associated with this entry.
  ///
  /// Read [Doos.getEntry] for more information.
  final ValueDeserializer<T> _deserializer;

  /// Internal method for disposing of this entry.
  ///
  /// Provided by [Doos.getEntry] upon creation.
  final Future<void> Function() _onDispose;

  /// The BehaviorSubject for this entry.
  ///
  /// Provided by [Doos.getEntry] upon creation.
  final BehaviorSubject<Object?> _subject;

  /// Internal method for handling onChange() calls.
  ///
  /// Provided by [Doos.getEntry] upon creation.
  final OnChangeHandler _handleOnChange;

  /// Returns a stream of changes to the value associated with this entry.
  ///
  /// Emits the new value whenever it changes. If [fetchInitialValue] is true
  /// (default), will also emit the current value when first called.
  ValueStream<T> onChange({bool fetchInitialValue = true}) {
    unawaited(_handleOnChange(key, fetchInitialValue));

    return _subject.stream
        .map((value) {
          try {
            return value == null ? null : _deserializer(value);
          } catch (error, stackTrace) {
            Error.throwWithStackTrace(error, stackTrace);
          }
        })
        .where((value) => value != null)
        .cast<T>()
        .distinct()
        .shareValue();
  }

  @override
  Future<void> dispose() async {
    await _onDispose();
  }

  /// Returns the value associated with this entry and assumes it is not `null`.
  ///
  /// If the value is `null`, returns a [DoosStorageNotFoundError]. If the value
  /// may be `null`, or a value for this entry's [key] may not exist, use
  /// [readOrNull] instead.
  Future<DoosResult<T, DoosStorageReadError>> read() => readOrNull().andThen(
    (value) =>
        value != null ? DoosOk(value) : DoosErr(DoosStorageNotFoundError(key)),
  );

  /// Returns the value associated with this entry, or `null` if the value is
  /// `null` or the key does not exist.
  ///
  /// If you are sure the value is not `null`, use [read] instead.
  Future<DoosResult<T?, DoosStorageReadError>> readOrNull() async {
    return _getValue().andThen((val) {
      if (val == null) {
        return const DoosOk(null);
      }

      try {
        final deserializedValue = _deserializer(val);
        return DoosOk(deserializedValue);
      } catch (error, stackTrace) {
        return DoosErr(
          DoosStorageDeserializationError(
            key: key,
            type: T.toString(),
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    });
  }

  /// Sets the value associated with this entry.
  ///
  /// If you want to remove the key, use [remove] instead.
  ///
  /// If you want to set the value only if the key does not exist, use
  /// [writeIfAbsent] instead.
  Future<DoosResult<void, DoosStorageWriteError>> write(T value) =>
      _setValue(value);

  /// Sets the value associated with this entry only if the key does not exist
  /// and returns `true` if no value was present.
  ///
  /// If you want to set the value even if the key exists, use [write] instead.
  /// If you want to remove the key, use [remove] instead.
  Future<DoosResult<bool, DoosStorageWriteError>> writeIfAbsent(T value) async {
    final readResult = await readOrNull();
    switch (readResult) {
      case DoosOk(value: final existingValue):
        if (existingValue == null) {
          final writeResult = await _setValue(value);
          return writeResult.map((_) => true);
        }
        return const DoosOk(false);
      case DoosErr(error: final error):
        return switch (error) {
          DoosStorageReadUnknownError(:final message) => DoosErr(
            DoosStorageWriteUnknownError(message),
          ),
          _ => DoosErr(
            DoosStorageWriteUnknownError(
              'Failed to check existing value: ${error.message}',
            ),
          ),
        };
    }
  }

  /// Removes the value associated with this entry and returns `true` if there
  /// was a value present (that is now removed).
  ///
  /// If you want to set the value, use [write] instead.
  Future<DoosResult<bool, DoosStorageRemoveError>> remove() async {
    final readResult = await readOrNull();
    switch (readResult) {
      case DoosOk(value: final existingValue):
        final writeResult = await _setValue(null);
        return switch (writeResult) {
          DoosOk() => DoosOk(existingValue != null),
          DoosErr(error: final error) => switch (error) {
            DoosStorageWriteUnknownError(:final message) => DoosErr(
              DoosStorageRemoveUnknownError(message),
            ),
            _ => DoosErr(
              DoosStorageRemoveUnknownError(
                'Failed to remove key: ${error.message}',
              ),
            ),
          },
        };
      case DoosErr(error: final error):
        return switch (error) {
          DoosStorageReadUnknownError(:final message) => DoosErr(
            DoosStorageRemoveUnknownError(message),
          ),
          _ => DoosErr(
            DoosStorageRemoveUnknownError(
              'Failed to check existing value: ${error.message}',
            ),
          ),
        };
    }
  }

  @override
  List<Object> get props => [key];
}

/// Internal state for songing storage entries.
class _StorageEntryState with EquatableMixin {
  const _StorageEntryState({
    required this.listeners,
    required this.subject,
    required this.initialValueFetched,
    required this.initialValueFetch,
  });

  final int listeners;
  final BehaviorSubject<Object?> subject;
  final bool initialValueFetched;
  final Future<void>? initialValueFetch;

  _StorageEntryState copyWith({
    int? listeners,
    BehaviorSubject<Object?>? subject,
    bool? initialValueFetched,
    Future<void>? initialValueFetch,
  }) {
    return _StorageEntryState(
      listeners: listeners ?? this.listeners,
      subject: subject ?? this.subject,
      initialValueFetched: initialValueFetched ?? this.initialValueFetched,
      initialValueFetch: initialValueFetch ?? this.initialValueFetch,
    );
  }

  @override
  List<Object?> get props => [
    listeners,
    subject,
    initialValueFetched,
    initialValueFetch,
  ];
}

/// A mixin that can be used to dispose of resources.
mixin Disposable {
  /// Disposes of the resources associated with this instance.
  ///
  /// Must be called before the last reference to this instance is lost. Not
  /// doing so will likely result in a memory leak.
  FutureOr<void> dispose();
}
