import 'package:doos/doos.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mock classes
class MockDoosStorageAdapter extends Mock implements DoosStorageAdapter {}

void main() {
  group('Doos', () {
    late DoosStorageAdapter adapter;

    setUp(() {
      adapter = MockDoosStorageAdapter();
      when(
        () => adapter.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => adapter.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => adapter.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});
      when(() => adapter.clear()).thenAnswer((_) async {});
    });

    Doos buildSubject() {
      return Doos(adapter: adapter);
    }

    group('constructor', () {
      test('creates instance with adapter', () {
        final subject = buildSubject();
        expect(subject, isA<Doos>());
      });
    });

    group('selfTest', () {
      test('returns true when storage is working correctly', () async {
        when(
          () => adapter.read(key: '_self_test'),
        ).thenAnswer((_) async => 'self_test_value');

        final subject = buildSubject();
        final result = await subject.selfTest();

        expect(result, isTrue);
        verify(
          () => adapter.write(key: '_self_test', value: 'self_test_value'),
        ).called(1);
        verify(() => adapter.read(key: '_self_test')).called(1);
        verify(() => adapter.delete(key: '_self_test')).called(1);
      });

      test('returns false when read value does not match', () async {
        when(
          () => adapter.read(key: '_self_test'),
        ).thenAnswer((_) async => 'wrong_value');

        final subject = buildSubject();
        final result = await subject.selfTest();

        expect(result, isFalse);
      });

      test('returns false when exception occurs', () async {
        when(
          () => adapter.write(key: '_self_test', value: 'self_test_value'),
        ).thenThrow(Exception('Storage error'));

        final subject = buildSubject();
        final result = await subject.selfTest();

        expect(result, isFalse);
      });
    });

    group('clear', () {
      test('calls adapter clear', () async {
        final subject = buildSubject();
        await subject.clear();

        verify(() => adapter.clear()).called(1);
      });
    });

    group('clearIfCorrupted', () {
      test('calls clear when selfTest returns false', () async {
        when(
          () => adapter.read(key: '_self_test'),
        ).thenAnswer((_) async => 'wrong_value');

        final subject = buildSubject();
        await subject.clearIfCorrupted();

        verify(() => adapter.clear()).called(1);
      });

      test('calls clear when selfTest throws exception', () async {
        when(
          () => adapter.write(key: '_self_test', value: 'self_test_value'),
        ).thenThrow(Exception('Storage error'));

        final subject = buildSubject();
        await subject.clearIfCorrupted();

        verify(() => adapter.clear()).called(1);
      });

      test('does not call clear when selfTest returns true', () async {
        when(
          () => adapter.read(key: '_self_test'),
        ).thenAnswer((_) async => 'self_test_value');

        final subject = buildSubject();
        await subject.clearIfCorrupted();

        verifyNever(() => adapter.clear());
      });
    });

    group('getEntry', () {
      test('creates entry with correct key', () {
        final subject = buildSubject();
        final entry = subject.getEntry<String>('test_key');

        expect(entry.key, equals('test_key'));
      });

      test('throws assertion error when T is dynamic', () {
        final subject = buildSubject();
        expect(
          () => subject.getEntry<dynamic>('test_key'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('uses identity deserializer by default', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenAnswer((_) async => '"test_value"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>('test_key');
        final result = await entry.readOrNull();

        expect(
          result,
          isA<DoosOk<String?, DoosStorageReadError>>().having(
            (e) => e.value,
            'value',
            equals('test_value'),
          ),
        );
      });

      test('uses custom deserializer when provided', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenAnswer((_) async => '"test_value"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>(
          'test_key',
          deserializer: (value) => 'custom_$value',
        );
        final result = await entry.readOrNull();

        expect(
          result,
          isA<DoosOk<String?, DoosStorageReadError>>().having(
            (e) => e.value,
            'value',
            equals('custom_test_value'),
          ),
        );
      });
    });

    group('read', () {
      test('returns null when adapter returns null', () async {
        when(() => adapter.read(key: 'test_key')).thenAnswer((_) async => null);

        final subject = buildSubject();
        final result = await subject.read('test_key');

        expect(
          result,
          isA<DoosOk<Object?, DoosStorageReadError>>().having(
            (e) => e.value,
            'value',
            isNull,
          ),
        );
      });

      test(
        'returns deserialized value when adapter returns valid JSON',
        () async {
          when(
            () => adapter.read(key: 'test_key'),
          ).thenAnswer((_) async => '"test_value"');

          final subject = buildSubject();
          final result = await subject.read('test_key');

          expect(
            result,
            isA<DoosOk<Object?, DoosStorageReadError>>().having(
              (e) => e.value,
              'value',
              equals('test_value'),
            ),
          );
        },
      );

      test('returns deserialization error when JSON is invalid', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenAnswer((_) async => 'invalid_json');

        final subject = buildSubject();
        final result = await subject.read('test_key');

        expect(
          result,
          isA<DoosErr<Object?, DoosStorageReadError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageDeserializationError>(),
          ),
        );
      });

      test('returns unknown error when adapter throws', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenThrow(Exception('Storage error'));

        final subject = buildSubject();
        final result = await subject.read('test_key');

        expect(
          result,
          isA<DoosErr<Object?, DoosStorageReadError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageReadUnknownError>(),
          ),
        );
      });
    });

    group('write', () {
      test('deletes key when value is null', () async {
        final subject = buildSubject();
        final result = await subject.write<String?>('test_key', null);

        expect(
          result,
          isA<DoosOk<void, DoosStorageWriteError>>().having(
            (e) => e.value,
            'value',
            isNull,
          ),
        );
        verify(() => adapter.delete(key: 'test_key')).called(1);
      });

      test('writes serialized value when value is not null', () async {
        final subject = buildSubject();
        final result = await subject.write<String>('test_key', 'test_value');

        expect(result, isA<DoosOk<void, DoosStorageWriteError>>());
        verify(
          () => adapter.write(key: 'test_key', value: '"test_value"'),
        ).called(1);
      });

      test(
        'deletes key when value is null even with non-nullable T',
        () async {
          final subject = buildSubject();
          final result = await subject.write<String>('test_key', null);

          expect(
            result,
            isA<DoosOk<void, DoosStorageWriteError>>().having(
              (e) => e.value,
              'value',
              isNull,
            ),
          );
          verify(() => adapter.delete(key: 'test_key')).called(1);
        },
      );

      test(
        'returns serialization error when value cannot be serialized',
        () async {
          final subject = buildSubject();
          final result = await subject.write<Object>('test_key', Object());

          expect(
            result,
            isA<DoosErr<void, DoosStorageWriteError>>().having(
              (e) => e.error,
              'error',
              isA<DoosStorageSerializationError>(),
            ),
          );
        },
      );

      test('returns unknown error when adapter throws', () async {
        when(
          () => adapter.write(key: 'test_key', value: '"test_value"'),
        ).thenThrow(Exception('Storage error'));

        final subject = buildSubject();
        final result = await subject.write<String>('test_key', 'test_value');

        expect(
          result,
          isA<DoosErr<void, DoosStorageWriteError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageWriteUnknownError>(),
          ),
        );
      });

      test('throws assertion error when T is dynamic', () {
        final subject = buildSubject();
        expect(
          () => subject.write<dynamic>('test_key', 'test_value'),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('serialize', () {
      test('serializes valid JSON value', () {
        final subject = buildSubject();
        final result = subject.serialize<String>('test_key', 'test_value');

        expect(
          result,
          isA<DoosOk<String, DoosStorageWriteError>>().having(
            (e) => e.value,
            'value',
            equals('"test_value"'),
          ),
        );
      });

      test('returns error when value is null', () {
        final subject = buildSubject();
        final result = subject.serialize<String?>('test_key', null);

        expect(
          result,
          isA<DoosErr<String, DoosStorageWriteError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageSerializationError>(),
          ),
        );
      });

      test('returns error when value cannot be serialized', () {
        final subject = buildSubject();
        final result = subject.serialize<Object>('test_key', Object());

        expect(
          result,
          isA<DoosErr<String, DoosStorageWriteError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageSerializationError>(),
          ),
        );
      });
    });

    group('onChange', () {
      test(
        'emits current value on first subscription '
        'when fetchInitialValue is true',
        () async {
          when(
            () => adapter.read(key: 'test_key'),
          ).thenAnswer((_) async => '"initial"');

          final subject = buildSubject();
          final entry = subject.getEntry<String>('test_key');

          await expectLater(entry.onChange().take(1), emits('initial'));
        },
      );

      test(
        'does not emit initial value when fetchInitialValue is false',
        () async {
          when(
            () => adapter.read(key: 'test_key'),
          ).thenAnswer((_) async => '"initial"');

          final subject = buildSubject();
          final entry = subject.getEntry<String>('test_key');

          final stream = entry.onChange(fetchInitialValue: false).take(1);

          // Trigger a write; only the written value should be emitted
          final future = expectLater(stream, emits('next'));
          await entry.write('next');
          await future;
        },
      );

      test('does not emit null on delete', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenAnswer((_) async => '"v1"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>('test_key');

        final stream = entry.onChange().take(2);
        final expectation = expectLater(stream, emitsInOrder(['v1', 'v3']));

        // Delete should not emit (null is filtered out)
        await entry.remove();
        await entry.write('v3');
        await expectation;
      });

      test('deduplicates identical consecutive values', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenAnswer((_) async => '"a"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>('test_key');

        final stream = entry.onChange().take(2);
        final expectation = expectLater(stream, emitsInOrder(['a', 'b']));

        await entry.write('a'); // Duplicate; should be ignored by distinct()
        await entry.write('b');
        await expectation;
      });

      test('emits error on read failure during initial fetch', () async {
        when(() => adapter.read(key: 'err_key')).thenThrow(Exception('boom'));

        final subject = buildSubject();
        final entry = subject.getEntry<String>('err_key');

        await expectLater(
          entry.onChange().take(1),
          emitsError(isA<DoosStorageReadUnknownError>()),
        );
      });

      test('emits error on write failure', () async {
        when(() => adapter.read(key: 'test_key')).thenAnswer((_) async => null);
        when(
          () => adapter.write(key: 'test_key', value: '"x"'),
        ).thenThrow(Exception('write failed'));

        final subject = buildSubject();
        final entry = subject.getEntry<String>('test_key');

        final expectation = expectLater(
          entry.onChange(fetchInitialValue: false).take(1),
          emitsError(isA<DoosStorageWriteUnknownError>()),
        );
        await entry.write('x');
        await expectation;
      });

      test('stops emitting after entry.dispose()', () async {
        when(
          () => adapter.read(key: 'test_key'),
        ).thenAnswer((_) async => '"v1"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>('test_key');

        final received = <String>[];
        final sub = entry.onChange().listen(received.add, onError: (_) {});

        // Wait for initial emission
        await expectLater(entry.onChange().take(1), emits('v1'));

        await entry.dispose();
        await subject.write<String>('test_key', 'v2');

        // Give some time for any unintended emission to propagate
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(received, equals(['v1']));
      });
    });

    group('writeIfAbsent', () {
      test('writes when value is absent and returns true', () async {
        when(() => adapter.read(key: 'k')).thenAnswer((_) async => null);

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.writeIfAbsent('val');

        expect(
          result,
          isA<DoosOk<bool, DoosStorageWriteError>>().having(
            (e) => e.value,
            'value',
            isTrue,
          ),
        );
        verify(() => adapter.write(key: 'k', value: '"val"')).called(1);
      });

      test('does not write when value exists and returns false', () async {
        when(
          () => adapter.read(key: 'k'),
        ).thenAnswer((_) async => '"existing"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.writeIfAbsent('val');

        expect(
          result,
          isA<DoosOk<bool, DoosStorageWriteError>>().having(
            (e) => e.value,
            'value',
            isFalse,
          ),
        );
        verifyNever(
          () => adapter.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
      });

      test('maps read unknown error to write unknown error', () async {
        when(() => adapter.read(key: 'k')).thenThrow(Exception('read fail'));

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.writeIfAbsent('val');

        expect(
          result,
          isA<DoosErr<bool, DoosStorageWriteError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageWriteUnknownError>(),
          ),
        );
      });
    });

    group('remove', () {
      test('returns true and deletes when value exists', () async {
        when(() => adapter.read(key: 'k')).thenAnswer((_) async => '"v"');

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.remove();

        expect(
          result,
          isA<DoosOk<bool, DoosStorageRemoveError>>().having(
            (e) => e.value,
            'value',
            isTrue,
          ),
        );
        verify(() => adapter.delete(key: 'k')).called(1);
      });

      test('returns false on delete when value does not exist', () async {
        when(() => adapter.read(key: 'k')).thenAnswer((_) async => null);

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.remove();

        expect(
          result,
          isA<DoosOk<bool, DoosStorageRemoveError>>().having(
            (e) => e.value,
            'value',
            isFalse,
          ),
        );
        verify(() => adapter.delete(key: 'k')).called(1);
      });

      test('maps write unknown error to remove unknown error', () async {
        when(() => adapter.read(key: 'k')).thenAnswer((_) async => '"v"');
        when(() => adapter.delete(key: 'k')).thenThrow(Exception('del fail'));

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.remove();

        expect(
          result,
          isA<DoosErr<bool, DoosStorageRemoveError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageRemoveUnknownError>(),
          ),
        );
      });

      test('maps read unknown error to remove unknown error', () async {
        when(() => adapter.read(key: 'k')).thenThrow(Exception('read fail'));

        final subject = buildSubject();
        final entry = subject.getEntry<String>('k');

        final result = await entry.remove();

        expect(
          result,
          isA<DoosErr<bool, DoosStorageRemoveError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageRemoveUnknownError>(),
          ),
        );
      });
    });
    group('deserializeJson', () {
      test('deserializes valid JSON', () {
        final subject = buildSubject();
        final result = subject.deserializeJson('test_key', '"test_value"');

        expect(
          result,
          isA<DoosOk<Object?, DoosStorageReadError>>().having(
            (e) => e.value,
            'value',
            equals('test_value'),
          ),
        );
      });

      test('returns error when JSON is invalid', () {
        final subject = buildSubject();
        final result = subject.deserializeJson('test_key', 'invalid_json');

        expect(
          result,
          isA<DoosErr<Object?, DoosStorageReadError>>().having(
            (e) => e.error,
            'error',
            isA<DoosStorageDeserializationError>(),
          ),
        );
      });
    });

    group('dispose', () {
      test('disposes all entries', () async {
        final subject = buildSubject()
          ..getEntry<String>('key1')
          ..getEntry<String>('key2');

        await subject.dispose();

        // NOTE(jeroen-meijer): We can't easily test that subjects are closed
        // without exposing internal state, but we can verify no exceptions are
        // thrown
        expect(subject.dispose, returnsNormally);
      });
    });
  });
}
