import 'package:doos/src/storage_adapter.dart';
import 'package:test/test.dart';

// Test implementation of DoosStorageAdapter
class TestStorageAdapter with DoosStorageAdapter {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

void main() {
  group('DoosStorageAdapter', () {
    late TestStorageAdapter adapter;

    setUp(() {
      adapter = TestStorageAdapter();
    });

    group('write', () {
      test('stores value with key', () async {
        await adapter.write(key: 'test_key', value: 'test_value');

        final result = await adapter.read(key: 'test_key');
        expect(result, equals('test_value'));
      });

      test('overwrites existing value', () async {
        await adapter.write(key: 'test_key', value: 'initial_value');
        await adapter.write(key: 'test_key', value: 'updated_value');

        final result = await adapter.read(key: 'test_key');
        expect(result, equals('updated_value'));
      });

      test('handles empty string value', () async {
        await adapter.write(key: 'test_key', value: '');

        final result = await adapter.read(key: 'test_key');
        expect(result, equals(''));
      });

      test('handles special characters in key and value', () async {
        const key = 'test/key with spaces & symbols!';
        const value = 'value with\nnewlines\tand\ttabs';
        
        await adapter.write(key: key, value: value);

        final result = await adapter.read(key: key);
        expect(result, equals(value));
      });
    });

    group('read', () {
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
      test('removes existing key', () async {
        await adapter.write(key: 'test_key', value: 'test_value');
        await adapter.delete(key: 'test_key');

        final result = await adapter.read(key: 'test_key');
        expect(result, isNull);
      });

      test('handles deletion of non-existent key gracefully', () async {
        // Should not throw an exception
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
        // Should not throw an exception
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
}
