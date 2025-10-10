// ignore_for_file: avoid_redundant_argument_values

import 'package:doos/src/storage_error.dart';
import 'package:test/test.dart';

void main() {
  group('DoosStorageReadError', () {
    test('has message property', () {
      const error = DoosStorageNotFoundError('test_key');
      expect(error.message, equals('Key "test_key" not found in storage'));
    });
  });

  group('DoosStorageWriteError', () {
    test('has message property', () {
      const error = DoosStorageSerializationError(
        key: 'test_key',
        type: 'String',
        originalError: 'test error',
      );
      expect(error.message, contains('Failed to serialize "test_key"'));
    });
  });

  group('DoosStorageRemoveError', () {
    test('has message property', () {
      const error = DoosStorageRemoveUnknownError('test error');
      expect(error.message, equals('test error'));
    });
  });

  group('DoosStorageNotFoundError', () {
    test('has correct message format', () {
      const error = DoosStorageNotFoundError('test_key');
      expect(error.message, equals('Key "test_key" not found in storage'));
    });

    test('toString returns class name and message', () {
      const error = DoosStorageNotFoundError('test_key');
      expect(
        error.toString(),
        equals('DoosStorageNotFoundError(Key "test_key" not found in storage)'),
      );
    });

    test('is final class', () {
      expect(DoosStorageNotFoundError, isA<Type>());
    });
  });

  group('DoosStorageTypeError', () {
    test('has correct message format', () {
      const error = DoosStorageTypeError(
        key: 'test_key',
        expectedType: 'String',
        actualType: 'int',
      );
      expect(
        error.message,
        equals('Type mismatch for key "test_key": expected String, got int'),
      );
    });

    test('toString returns class name and message', () {
      const error = DoosStorageTypeError(
        key: 'test_key',
        expectedType: 'String',
        actualType: 'int',
      );
      expect(
        error.toString(),
        equals(
          'DoosStorageTypeError(Type mismatch for key "test_key": '
          'expected String, got int)',
        ),
      );
    });

    test('is final class', () {
      expect(DoosStorageTypeError, isA<Type>());
    });
  });

  group('DoosStorageDeserializationError', () {
    test('has correct message format with original error', () {
      const error = DoosStorageDeserializationError(
        key: 'test_key',
        type: 'String',
        error: 'test error',
      );
      expect(
        error.message,
        equals('Failed to deserialize "test_key" to String: test error'),
      );
    });

    test('has correct message format without original error', () {
      const error = DoosStorageDeserializationError(
        key: 'test_key',
        type: 'String',
      );
      expect(
        error.message,
        equals('Failed to deserialize "test_key" to String'),
      );
    });

    test('toString returns class name and message', () {
      const error = DoosStorageDeserializationError(
        key: 'test_key',
        type: 'String',
        error: 'test error',
      );
      expect(
        error.toString(),
        equals(
          'DoosStorageDeserializationError(Failed to deserialize "test_key" '
          'to String: test error)',
        ),
      );
    });

    test('is final class', () {
      expect(DoosStorageDeserializationError, isA<Type>());
    });
  });

  group('DoosStorageSerializationError', () {
    test('has correct message format with original error', () {
      const error = DoosStorageSerializationError(
        key: 'test_key',
        type: 'String',
        originalError: 'test error',
      );
      expect(
        error.message,
        equals('Failed to serialize "test_key" of type String: test error'),
      );
    });

    test('has correct message format without original error', () {
      const error = DoosStorageSerializationError(
        key: 'test_key',
        type: 'String',
      );
      expect(
        error.message,
        equals('Failed to serialize "test_key" of type String'),
      );
    });

    test('toString returns class name and message', () {
      const error = DoosStorageSerializationError(
        key: 'test_key',
        type: 'String',
        originalError: 'test error',
      );
      expect(
        error.toString(),
        equals(
          'DoosStorageSerializationError(Failed to serialize "test_key" '
          'of type String: test error)',
        ),
      );
    });

    test('is final class', () {
      expect(DoosStorageSerializationError, isA<Type>());
    });
  });

  group('DoosStorageReadUnknownError', () {
    test('creates instance with message', () {
      const error = DoosStorageReadUnknownError('test error');
      expect(error.message, equals('test error'));
    });

    test('creates instance without message', () {
      const error = DoosStorageReadUnknownError();
      expect(error.message, equals('Unknown storage error during read'));
    });

    test('toString returns class name and message', () {
      const error = DoosStorageReadUnknownError('test error');
      expect(
        error.toString(),
        equals('DoosStorageReadUnknownError(test error)'),
      );
    });

    test('is final class', () {
      expect(DoosStorageReadUnknownError, isA<Type>());
    });
  });

  group('DoosStorageWriteUnknownError', () {
    test('creates instance with message', () {
      const error = DoosStorageWriteUnknownError('test error');
      expect(error.message, equals('test error'));
    });

    test('creates instance without message', () {
      const error = DoosStorageWriteUnknownError();
      expect(error.message, equals('Unknown storage error during write'));
    });

    test('creates instance with null message', () {
      const error = DoosStorageWriteUnknownError();
      expect(error.message, equals('Unknown storage error during write'));
    });

    test('toString returns class name and message', () {
      const error = DoosStorageWriteUnknownError('test error');
      expect(
        error.toString(),
        equals('DoosStorageWriteUnknownError(test error)'),
      );
    });

    test('is final class', () {
      expect(DoosStorageWriteUnknownError, isA<Type>());
    });
  });

  group('DoosStorageRemoveUnknownError', () {
    test('creates instance with message', () {
      const error = DoosStorageRemoveUnknownError('test error');
      expect(error.message, equals('test error'));
    });

    test('creates instance without message', () {
      const error = DoosStorageRemoveUnknownError();
      expect(error.message, equals('Unknown storage error during remove'));
    });

    test('creates instance with null message', () {
      const error = DoosStorageRemoveUnknownError();
      expect(error.message, equals('Unknown storage error during remove'));
    });

    test('toString returns class name and message', () {
      const error = DoosStorageRemoveUnknownError('test error');
      expect(
        error.toString(),
        equals('DoosStorageRemoveUnknownError(test error)'),
      );
    });

    test('is final class', () {
      expect(DoosStorageRemoveUnknownError, isA<Type>());
    });
  });

  group('error hierarchy', () {
    test('DoosStorageNotFoundError is a DoosStorageReadError', () {
      const error = DoosStorageNotFoundError('test_key');
      expect(error, isA<DoosStorageReadError>());
    });

    test('DoosStorageTypeError is a DoosStorageReadError', () {
      const error = DoosStorageTypeError(
        key: 'test_key',
        expectedType: 'String',
        actualType: 'int',
      );
      expect(error, isA<DoosStorageReadError>());
    });

    test('DoosStorageDeserializationError is a DoosStorageReadError', () {
      const error = DoosStorageDeserializationError(
        key: 'test_key',
        type: 'String',
      );
      expect(error, isA<DoosStorageReadError>());
    });

    test('DoosStorageReadUnknownError is a DoosStorageReadError', () {
      const error = DoosStorageReadUnknownError('test error');
      expect(error, isA<DoosStorageReadError>());
    });

    test('DoosStorageSerializationError is a DoosStorageWriteError', () {
      const error = DoosStorageSerializationError(
        key: 'test_key',
        type: 'String',
      );
      expect(error, isA<DoosStorageWriteError>());
    });

    test('DoosStorageWriteUnknownError is a DoosStorageWriteError', () {
      const error = DoosStorageWriteUnknownError('test error');
      expect(error, isA<DoosStorageWriteError>());
    });

    test('DoosStorageRemoveUnknownError is a DoosStorageRemoveError', () {
      const error = DoosStorageRemoveUnknownError('test error');
      expect(error, isA<DoosStorageRemoveError>());
    });
  });
}
