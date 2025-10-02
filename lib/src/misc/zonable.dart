import 'dart:async';

final class Zonable<T> {
  T call() => fromZone<T>();

  static T fromZone<T>() {
    return Zone.current[T] as T? ??
        (throw StateError('No instance of $T found in zone'));
  }

  static R inject<R>(Object zonable, R Function() fn) {
    return injectMany([zonable], fn);
  }

  static R injectMany<R>(List<Object> zonables, R Function() fn) {
    return Zone.current
        .fork(
          zoneValues: {
            for (final zonable in zonables) zonable.runtimeType: zonable,
          },
        )
        .run(fn);
  }
}
