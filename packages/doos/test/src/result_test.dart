// ignore: lines_longer_than_80_chars
// ignore_for_file: deprecated_member_use_from_same_package, prefer_const_constructors

import 'package:doos/src/result.dart';
import 'package:test/test.dart';

void main() {
  group('DoosResult', () {
    group('DoosOk', () {
      test('creates instance with value', () {
        const result = DoosOk<String, String>('test_value');
        expect(result.value, equals('test_value'));
      });

      test('valueOrNull returns value', () {
        const result = DoosOk<String, String>('test_value');
        expect(result.valueOrNull, equals('test_value'));
      });

      test('errorOrNull returns null', () {
        const result = DoosOk<String, String>('test_value');
        expect(result.errorOrNull, isNull);
      });

      test('map transforms value', () {
        const result = DoosOk<int, String>(42);
        final mapped = result.map((value) => value * 2);
        expect(mapped.value, equals(84));
      });

      test('mapError does not transform error', () {
        const result = DoosOk<String, String>('test_value');
        final mapped = result.mapError((error) => 'new_error');
        expect(mapped.value, equals('test_value'));
      });

      test('andThen calls function with value', () {
        const result = DoosOk<int, String>(42);
        final chained = result.andThen(
          (value) => DoosOk<int, String>(value * 2),
        );
        expect(chained, isA<DoosOk<int, String>>());
        if (chained is DoosOk<int, String>) {
          expect(chained.value, equals(84));
        }
      });

      test('orElse does not call function', () {
        const result = DoosOk<String, String>('test_value');
        final chained = result.orElse(
          (error) => DoosOk<String, String>('fallback'),
        );
        expect(chained, isA<DoosOk<String, String>>());
        if (chained is DoosOk<String, String>) {
          expect(chained.value, equals('test_value'));
        }
      });

      test('props includes value', () {
        const result = DoosOk<String, String>('test_value');
        expect(result.props, equals(['test_value']));
      });
    });

    group('DoosErr', () {
      test('creates instance with error', () {
        const result = DoosErr<String, String>('test_error');
        expect(result.error, equals('test_error'));
      });

      test('valueOrNull returns null', () {
        const result = DoosErr<String, String>('test_error');
        expect(result.valueOrNull, isNull);
      });

      test('errorOrNull returns error', () {
        const result = DoosErr<String, String>('test_error');
        expect(result.errorOrNull, equals('test_error'));
      });

      test('map does not transform value', () {
        const result = DoosErr<String, String>('test_error');
        final mapped = result.map((value) => 'new_value');
        expect(mapped, isA<DoosErr<String, String>>());
        if (mapped is DoosErr<String, String>) {
          expect(mapped.error, equals('test_error'));
        }
      });

      test('mapError transforms error', () {
        const result = DoosErr<String, String>('test_error');
        final mapped = result.mapError((error) => 'new_error');
        expect(mapped, isA<DoosErr<String, String>>());
        if (mapped is DoosErr<String, String>) {
          expect(mapped.error, equals('new_error'));
        }
      });

      test('andThen does not call function', () {
        const result = DoosErr<String, String>('test_error');
        final chained = result.andThen(
          (value) => DoosOk<String, String>('new_value'),
        );
        expect(chained, isA<DoosErr<String, String>>());
        if (chained is DoosErr<String, String>) {
          expect(chained.error, equals('test_error'));
        }
      });

      test('orElse calls function with error', () {
        const result = DoosErr<String, String>('test_error');
        final chained = result.orElse(
          (error) => DoosOk<String, String>('fallback'),
        );
        expect(chained, isA<DoosOk<String, String>>());
        if (chained is DoosOk<String, String>) {
          expect(chained.value, equals('fallback'));
        }
      });

      test('props includes error', () {
        const result = DoosErr<String, String>('test_error');
        expect(result.props, equals(['test_error']));
      });
    });
  });

  group('DoosResultFutureExtension', () {
    group('map', () {
      test('maps successful future result', () async {
        final future = Future.value(const DoosOk<int, String>(42));
        final mapped = future.map((value) => value * 2);
        final result = await mapped;

        expect(
          result,
          isA<DoosOk<int, String>>().having(
            (e) => e.value,
            'value',
            equals(84),
          ),
        );
      });

      test('preserves error in future result', () async {
        final future = Future.value(const DoosErr<int, String>('test_error'));
        final mapped = future.map((value) => value * 2);
        final result = await mapped;

        expect(
          result,
          isA<DoosErr<int, String>>().having(
            (e) => e.error,
            'error',
            equals('test_error'),
          ),
        );
      });
    });

    group('mapError', () {
      test('preserves success in future result', () async {
        final future = Future.value(const DoosOk<int, String>(42));
        final mapped = future.mapError((error) => 'new_error');
        final result = await mapped;

        expect(
          result,
          isA<DoosOk<int, String>>().having(
            (e) => e.value,
            'value',
            equals(42),
          ),
        );
      });

      test('maps error in future result', () async {
        final future = Future.value(const DoosErr<int, String>('test_error'));
        final mapped = future.mapError((error) => 'new_error');
        final result = await mapped;

        expect(result, isA<DoosErr<int, String>>());
        if (result is DoosErr<int, String>) {
          expect(result.error, equals('new_error'));
        }
      });
    });

    group('andThen', () {
      test('chains successful future result', () async {
        final future = Future.value(const DoosOk<int, String>(42));
        final chained = future.andThen(
          (value) => DoosOk<int, String>(value * 2),
        );
        final result = await chained;

        expect(
          result,
          isA<DoosOk<int, String>>().having(
            (e) => e.value,
            'value',
            equals(84),
          ),
        );
      });

      test('preserves error in future result', () async {
        final future = Future.value(const DoosErr<int, String>('test_error'));
        final chained = future.andThen(
          (value) => DoosOk<int, String>(value * 2),
        );
        final result = await chained;

        expect(
          result,
          isA<DoosErr<int, String>>().having(
            (e) => e.error,
            'error',
            equals('test_error'),
          ),
        );
      });
    });

    group('orElse', () {
      test('preserves success in future result', () async {
        final future = Future.value(const DoosOk<int, String>(42));
        final chained = future.orElse((error) => DoosOk<int, String>(0));
        final result = await chained;

        expect(
          result,
          isA<DoosOk<int, String>>().having(
            (e) => e.value,
            'value',
            equals(42),
          ),
        );
      });

      test('chains error in future result', () async {
        final future = Future.value(const DoosErr<int, String>('test_error'));
        final chained = future.orElse((error) => DoosOk<int, String>(0));
        final result = await chained;

        expect(
          result,
          isA<DoosOk<int, String>>().having(
            (e) => e.value,
            'value',
            equals(0),
          ),
        );
      });
    });
  });
}
