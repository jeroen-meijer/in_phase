import 'dart:async';

import 'package:in_phase/src/logger/logger.dart';

typedef TeardownFn = FutureOr<void> Function();

typedef AddTeardownFn = void Function(TeardownFn teardown);

Future<T> withTeardown<T>(
  FutureOr<T> Function(AddTeardownFn addTeardown) fn,
) async {
  final teardowns = <TeardownFn>[];

  try {
    return await fn(teardowns.add);
  } finally {
    for (final teardown in teardowns) {
      try {
        await teardown();
      } catch (e, st) {
        log.error(
          'Error while running teardown:\n\n$e\n\n$st',
        );
      }
    }
  }
}
