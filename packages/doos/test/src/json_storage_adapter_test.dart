import 'dart:convert';
import 'dart:io';

import 'package:doos/src/json_storage_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('DoosJsonStorageAdapter', () {
    late Directory tempDir;
    late File testFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('doos_test_');
      testFile = File('${tempDir.path}/test.json');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('create', () {
      test(
        'creates adapter with new file when createFileIfNotExists is true',
        () async {
          final adapter = await DoosJsonStorageAdapter.create(
            file: testFile,
          );

          expect(adapter, isA<DoosJsonStorageAdapter>());
          expect(testFile.existsSync(), isTrue);
        },
      );

      test(
        'throws FileNotFoundException when file does not exist '
        'and createFileIfNotExists is false',
        () async {
          expect(
            () => DoosJsonStorageAdapter.create(
              file: testFile,
              createFileIfNotExists: false,
            ),
            throwsA(isA<FileNotFoundException>()),
          );
        },
      );

      test('loads existing file data', () async {
        testFile.writeAsStringSync('{"key1": "value1", "key2": "value2"}');

        final adapter = await DoosJsonStorageAdapter.create(
          file: testFile,
        );

        final value1 = await adapter.read(key: 'key1');
        final value2 = await adapter.read(key: 'key2');

        expect(value1, equals('value1'));
        expect(value2, equals('value2'));
      });

      test(
        'clears file when clearFileOnReadError is true and JSON is invalid',
        () async {
          testFile.writeAsStringSync('invalid json');

          await DoosJsonStorageAdapter.create(
            file: testFile,
            clearFileOnReadError: true,
          );

          expect(testFile.readAsStringSync(), equals('{}'));
        },
      );

      test(
        'throws JsonDecodeError when clearFileOnReadError is false '
        'and JSON is invalid',
        () async {
          testFile.writeAsStringSync('invalid json');

          expect(
            () => DoosJsonStorageAdapter.create(
              file: testFile,
            ),
            throwsA(isA<JsonDecodeError>()),
          );
        },
      );

      test(
        'clears file when clearFileOnReadError is true '
        'and data is not Map<String, String>',
        () async {
          testFile.writeAsStringSync('["array", "data"]');

          await DoosJsonStorageAdapter.create(
            file: testFile,
            clearFileOnReadError: true,
          );

          expect(testFile.readAsStringSync(), equals('{}'));
        },
      );

      test(
        'throws JsonDecodeError when clearFileOnReadError is false '
        'and data is not Map<String, String>',
        () async {
          testFile.writeAsStringSync('["array", "data"]');

          expect(
            () => DoosJsonStorageAdapter.create(
              file: testFile,
            ),
            throwsA(isA<JsonDecodeError>()),
          );
        },
      );
    });

    group('write', () {
      late DoosJsonStorageAdapter adapter;

      setUp(() async {
        adapter = await DoosJsonStorageAdapter.create(
          file: testFile,
        );
      });

      test('writes value to file', () async {
        await adapter.write(key: 'test_key', value: 'test_value');

        final fileContent = testFile.readAsStringSync();
        final data = jsonDecode(fileContent) as Map<String, dynamic>;

        expect(data['test_key'], equals('test_value'));
      });

      test('overwrites existing value', () async {
        await adapter.write(key: 'test_key', value: 'initial_value');
        await adapter.write(key: 'test_key', value: 'updated_value');

        final fileContent = testFile.readAsStringSync();
        final data = jsonDecode(fileContent) as Map<String, dynamic>;

        expect(data['test_key'], equals('updated_value'));
      });

      test('handles special characters in key and value', () async {
        const key = 'test/key with spaces & symbols!';
        const value = 'value with\nnewlines\tand\ttabs';

        await adapter.write(key: key, value: value);

        final fileContent = testFile.readAsStringSync();
        final data = jsonDecode(fileContent) as Map<String, dynamic>;

        expect(data[key], equals(value));
      });
    });

    group('read', () {
      late DoosJsonStorageAdapter adapter;

      setUp(() async {
        adapter = await DoosJsonStorageAdapter.create(
          file: testFile,
        );
      });

      test('returns null for non-existent key', () async {
        final result = await adapter.read(key: 'non_existent_key');
        expect(result, isNull);
      });

      test('returns stored value for existing key', () async {
        await adapter.write(key: 'test_key', value: 'test_value');

        final result = await adapter.read(key: 'test_key');
        expect(result, equals('test_value'));
      });

      test('returns null for deleted key', () async {
        await adapter.write(key: 'test_key', value: 'test_value');
        await adapter.delete(key: 'test_key');

        final result = await adapter.read(key: 'test_key');
        expect(result, isNull);
      });
    });

    group('delete', () {
      late DoosJsonStorageAdapter adapter;

      setUp(() async {
        adapter = await DoosJsonStorageAdapter.create(
          file: testFile,
        );
      });

      test('removes existing key', () async {
        await adapter.write(key: 'test_key', value: 'test_value');
        await adapter.delete(key: 'test_key');

        final result = await adapter.read(key: 'test_key');
        expect(result, isNull);
      });

      test('handles deletion of non-existent key gracefully', () async {
        expect(() => adapter.delete(key: 'non_existent_key'), returnsNormally);
      });

      test('only removes specified key', () async {
        await adapter.write(key: 'key1', value: 'value1');
        await adapter.write(key: 'key2', value: 'value2');
        await adapter.delete(key: 'key1');

        final result1 = await adapter.read(key: 'key1');
        final result2 = await adapter.read(key: 'key2');

        expect(result1, isNull);
        expect(result2, equals('value2'));
      });
    });

    group('clear', () {
      late DoosJsonStorageAdapter adapter;

      setUp(() async {
        adapter = await DoosJsonStorageAdapter.create(
          file: testFile,
        );
      });

      test('removes all keys', () async {
        await adapter.write(key: 'key1', value: 'value1');
        await adapter.write(key: 'key2', value: 'value2');
        await adapter.write(key: 'key3', value: 'value3');

        await adapter.clear();

        final result1 = await adapter.read(key: 'key1');
        final result2 = await adapter.read(key: 'key2');
        final result3 = await adapter.read(key: 'key3');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      test('handles clear on empty storage', () async {
        expect(() => adapter.clear(), returnsNormally);
      });

      test('allows writing after clear', () async {
        await adapter.write(key: 'key1', value: 'value1');
        await adapter.clear();
        await adapter.write(key: 'key2', value: 'value2');

        final result = await adapter.read(key: 'key2');
        expect(result, equals('value2'));
      });
    });

    group('integration', () {
      late DoosJsonStorageAdapter adapter;

      setUp(() async {
        adapter = await DoosJsonStorageAdapter.create(
          file: testFile,
        );
      });

      test('complete workflow', () async {
        // Write multiple values
        await adapter.write(key: 'user_name', value: 'John Doe');
        await adapter.write(key: 'user_age', value: '30');
        await adapter.write(key: 'user_email', value: 'john@example.com');

        // Read values
        final name = await adapter.read(key: 'user_name');
        final age = await adapter.read(key: 'user_age');
        final email = await adapter.read(key: 'user_email');

        expect(name, equals('John Doe'));
        expect(age, equals('30'));
        expect(email, equals('john@example.com'));

        // Update a value
        await adapter.write(key: 'user_age', value: '31');
        final updatedAge = await adapter.read(key: 'user_age');
        expect(updatedAge, equals('31'));

        // Delete a value
        await adapter.delete(key: 'user_email');
        final deletedEmail = await adapter.read(key: 'user_email');
        expect(deletedEmail, isNull);

        // Clear all
        await adapter.clear();
        final clearedName = await adapter.read(key: 'user_name');
        final clearedAge = await adapter.read(key: 'user_age');
        expect(clearedName, isNull);
        expect(clearedAge, isNull);
      });

      test('concurrent operations', () async {
        // Write multiple values concurrently
        await Future.wait([
          adapter.write(key: 'key1', value: 'value1'),
          adapter.write(key: 'key2', value: 'value2'),
          adapter.write(key: 'key3', value: 'value3'),
        ]);

        // Read all values
        final results = await Future.wait([
          adapter.read(key: 'key1'),
          adapter.read(key: 'key2'),
          adapter.read(key: 'key3'),
        ]);

        expect(results, equals(['value1', 'value2', 'value3']));
      });
    });
  });

  group('DoosJsonStorageAdapterError', () {
    test('is abstract class', () {
      expect(DoosJsonStorageAdapterError, isA<Type>());
    });
  });

  group('FileNotFoundException', () {
    test('creates instance with file', () {
      final file = File('test.json');
      final error = FileNotFoundException(file);

      expect(error.file, equals(file));
    });

    test('toString returns class name and file', () {
      final file = File('test.json');
      final error = FileNotFoundException(file);

      expect(
        error.toString(),
        equals("FileNotFoundException(File: 'test.json')"),
      );
    });

    test('is final class', () {
      expect(FileNotFoundException, isA<Type>());
    });
  });

  group('JsonDecodeError', () {
    test('creates instance with file and error', () {
      final file = File('test.json');
      final originalError = Exception('test error');
      final error = JsonDecodeError(file, originalError);

      expect(error.file, equals(file));
      expect(error.error, equals(originalError));
    });

    test('toString returns class name, file and error', () {
      final file = File('test.json');
      final originalError = Exception('test error');
      final error = JsonDecodeError(file, originalError);

      expect(
        error.toString(),
        equals("JsonDecodeError(File: 'test.json', Exception: test error)"),
      );
    });

    test('is final class', () {
      expect(JsonDecodeError, isA<Type>());
    });
  });
}
