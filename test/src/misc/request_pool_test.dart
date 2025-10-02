import 'dart:async';

import 'package:rkdb_dart/src/misc/request_pool.dart';
import 'package:test/test.dart';

void main() {
  group('RequestPool', () {
    test('deduplicates identical identifier and returns same Future', () async {
      final pool = RequestPool();

      var callCount = 0;
      Future<int> fn() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      }

      final f1 = pool.request(fn, identifier: 'id-1');
      final f2 = pool.request(fn, identifier: 'id-1');

      expect(f1, same(f2));
      expect(await f1, 42);
      expect(await f2, 42);
      expect(callCount, 1);
    });

    test('two different identifiers do not deduplicate', () async {
      final pool = RequestPool();

      var callCount = 0;
      Future<int> fn() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 7;
      }

      final f1 = pool.request(fn, identifier: 'a');
      final f2 = pool.request(fn, identifier: 'b');

      expect(f1, isNot(same(f2)));
      expect(await f1, 7);
      expect(await f2, 7);
      expect(callCount, 2);
    });

    test('force restarts request and both A and B get forced result', () async {
      final pool = RequestPool();

      final results = <int>[];

      Future<int> slowA() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return 1;
      }

      Future<int> fastB() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 2;
      }

      final fa = pool.request(slowA, identifier: 'same');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final fb = pool.request(fastB, identifier: 'same', force: true);

      results
        ..add(await fa)
        ..add(await fb);

      expect(results, equals([2, 2]));
    });

    test('retries failing request until success', () async {
      final pool = RequestPool(
        maxRetries: 2,
        retryDelay: const Duration(milliseconds: 10),
      );

      var attempts = 0;
      Future<String> flaky() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('rate');
        }
        return 'ok';
      }

      final result = await pool.request(flaky, identifier: 'flaky');
      expect(result, 'ok');
      expect(attempts, 2);
    });

    test('retryFailed=false returns old failed Future', () async {
      final pool = RequestPool(
        maxRetries: 0,
        retryDelay: const Duration(milliseconds: 5),
      );

      Future<int> alwaysFail() async => throw StateError('boom');

      final f1 = pool.request(alwaysFail, identifier: 'err');
      await expectLater(f1, throwsA(isA<StateError>()));

      Future<int> wouldSucceed() async => 99;

      final f2 = pool.request(
        wouldSucceed,
        identifier: 'err',
        retryFailed: false,
      );

      expect(f2, same(f1));
      await expectLater(f2, throwsA(isA<StateError>()));
    });

    test('retryFailed=true after failure starts a new run', () async {
      final pool = RequestPool(
        maxRetries: 0,
        retryDelay: const Duration(milliseconds: 5),
      );

      var fail = true;
      Future<int> flaky() async {
        if (fail) throw Exception('x');
        return 7;
      }

      final f1 = pool.request(flaky, identifier: 'k');
      await expectLater(f1, throwsA(isException));

      fail = false;
      final f2 = pool.request(flaky, identifier: 'k');

      expect(f2, isNot(same(f1)));
      expect(await f2, 7);
    });

    test('TTL removes failed cached Future after expiry', () async {
      final pool = RequestPool(
        maxRetries: 0,
        retryDelay: const Duration(milliseconds: 5),
      );

      Future<int> alwaysFail() async => throw Exception('fail');

      final f1 = pool.request(
        alwaysFail,
        identifier: 'ttl-key',
        ttl: const Duration(milliseconds: 50),
      );
      await expectLater(f1, throwsA(isException));

      final beforeTtl = pool.request(
        alwaysFail,
        identifier: 'ttl-key',
        retryFailed: false,
      );
      expect(beforeTtl, same(f1));

      await Future<void>.delayed(const Duration(milliseconds: 60));

      var ran = false;
      Future<int> succeed() async {
        ran = true;
        return 5;
      }

      final afterTtl = pool.request(
        succeed,
        identifier: 'ttl-key',
        retryFailed: false,
      );

      expect(await afterTtl, 5);
      expect(ran, isTrue);
    });

    test('respects maxConcurrent', () async {
      final pool = RequestPool(
        maxConcurrent: 2,
        retryDelay: const Duration(milliseconds: 5),
      );

      var running = 0;
      var maxObserved = 0;

      Future<void> task(String id) async {
        running++;
        if (running > maxObserved) maxObserved = running;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        running--;
      }

      final futures = <Future<void>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(pool.request(() => task('t$i'), identifier: 't$i'));
      }

      await Future.wait(futures);
      expect(maxObserved, lessThanOrEqualTo(2));
    });

    test('returns cached success within TTL without re-running', () async {
      final pool = RequestPool(
        defaultTtl: const Duration(seconds: 5),
      );

      var calls = 0;
      Future<int> fetch() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 123;
      }

      final first = await pool.request(fetch, identifier: 'ttl-ok');
      expect(first, 123);
      expect(calls, 1);

      // Immediately call again: should return cached success, not re-run
      final second = await pool.request(fetch, identifier: 'ttl-ok');
      expect(second, 123);
      expect(calls, 1);
    });

    test('does not cache success when ttl is Duration.zero', () async {
      final pool = RequestPool(
        defaultTtl: const Duration(seconds: 5),
      );

      var calls = 0;
      Future<int> fetch() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 7;
      }

      final first = await pool.request(
        fetch,
        identifier: 'ttl-zero',
        ttl: Duration.zero,
      );
      expect(first, 7);
      expect(calls, 1);

      // TTL disabled: next call should re-run
      final second = await pool.request(
        fetch,
        identifier: 'ttl-zero',
        ttl: Duration.zero,
      );
      expect(second, 7);
      expect(calls, 2);
    });
  });
}
