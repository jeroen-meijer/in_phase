import 'package:equatable/equatable.dart';

/// {@template doos_result}
/// A result of an operation.
///
/// Can be either:
/// - [DoosOk] if the operation was successful
/// - [DoosErr] if the operation failed
/// {@endtemplate}
sealed class DoosResult<T, E> with EquatableMixin {
  /// {@macro doos_result}
  const DoosResult();

  /// The value of the result, if any.
  T? get valueOrNull;

  /// The error of the result, if any.
  E? get errorOrNull;

  /// If this is a [DoosOk], maps the inner value to a new [DoosOk]. Otherwise,
  /// returns a new [DoosErr] with the same error.
  DoosResult<T2, E> map<T2>(T2 Function(T) fn);

  /// If this is a [DoosErr], maps the inner error to a new [DoosErr].
  /// Otherwise, returns a new [DoosOk] with the same value.
  DoosResult<T, E2> mapError<E2>(E2 Function(E) fn);

  /// If this is a [DoosOk], returns the result of the given function.
  /// Otherwise, returns a new [DoosErr] with the same error.
  DoosResult<T2, E> andThen<T2>(DoosResult<T2, E> Function(T) fn);

  /// If this is a [DoosErr], returns the result of the given function.
  /// Otherwise, returns a new [DoosOk] with the same value.
  DoosResult<T, E2> orElse<E2>(DoosResult<T, E2> Function(E) fn);
}

/// {@template doos_ok}
/// A successful result.
///
/// Contains a [value].
/// {@endtemplate}
class DoosOk<T, E> extends DoosResult<T, E> {
  /// {@macro doos_ok}
  const DoosOk(this.value);

  /// The value of the result.
  final T value;

  @override
  @Redundant(
    'Redundant. Will always return the value. '
    'Avoid calling this.',
  )
  T? get valueOrNull => value;

  @override
  @Redundant(
    'Redundant. Will always return null. '
    'Avoid calling this.',
  )
  E? get errorOrNull => null;

  @override
  @Redundant(
    'Redundant. Will always call the given function. '
    'Avoid calling this and use the [value] directly instead.',
  )
  DoosOk<T2, E> map<T2>(T2 Function(T) fn) => DoosOk(fn(value));

  @override
  @Redundant(
    'Redundant. Will never run the given function since this is known to be a '
    '[DoosOk]. '
    'Avoid calling this.',
  )
  DoosOk<T, E2> mapError<E2>(E2 Function(E) fn) => DoosOk(value);

  @override
  @Redundant(
    'Redundant. Will always call the given function. '
    'Avoid calling this and use the [value] directly instead.',
  )
  DoosResult<T2, E> andThen<T2>(DoosResult<T2, E> Function(T) fn) => fn(value);

  @override
  @Redundant(
    'Redundant. Will never run the given function since this is known to be a '
    '[DoosOk]. '
    'Avoid calling this and use the [error] directly instead.',
  )
  DoosResult<T, E2> orElse<E2>(DoosResult<T, E2> Function(E) fn) =>
      DoosOk(value);

  @override
  List<Object?> get props => [value];
}

/// {@template doos_err}
/// A failed result.
///
/// Contains an [error].
/// {@endtemplate}
class DoosErr<T, E> extends DoosResult<T, E> {
  /// {@macro doos_err}
  const DoosErr(this.error);

  /// The error of the result.
  final E error;

  @override
  @Redundant(
    'Redundant. Will always return null. '
    'Avoid calling this.',
  )
  T? get valueOrNull => null;

  @override
  @Redundant(
    'Redundant. Will always return the error. '
    'Avoid calling this.',
  )
  E? get errorOrNull => error;

  @override
  @Redundant(
    'Redundant. Will never call the given function since this is known to be a '
    '[DoosErr]. '
    'Avoid calling this.',
  )
  DoosResult<T2, E> map<T2>(T2 Function(T) fn) => DoosErr(error);

  @override
  @Redundant(
    'Redundant. Will always call the given function. '
    'Avoid calling this and use the [error] directly instead.',
  )
  DoosResult<T, E2> mapError<E2>(E2 Function(E) fn) => DoosErr(fn(error));

  @override
  @Redundant(
    'Redundant. Will never call the given function since this is known to be a '
    '[DoosErr]. '
    'Avoid calling this.',
  )
  DoosResult<T2, E> andThen<T2>(DoosResult<T2, E> Function(T) fn) =>
      DoosErr(error);

  @override
  @Redundant(
    'Redundant. Will always call the given function. '
    'Avoid calling this and use the [error] directly instead.',
  )
  DoosResult<T, E2> orElse<E2>(DoosResult<T, E2> Function(E) fn) => fn(error);

  @override
  List<Object?> get props => [error];
}

/// Extensions on [Future]s that return [DoosResult]s.
extension DoosResultFutureExtension<T, E> on Future<DoosResult<T, E>> {
  /// Awaits this future, then, if this is a [DoosOk], maps the inner value to a
  /// new [DoosOk]. Otherwise, returns a new [DoosErr] with the same error.
  Future<DoosResult<T2, E>> map<T2>(T2 Function(T) fn) =>
      then((result) => result.map(fn));

  /// Awaits this future, then, if this is a [DoosErr], maps the inner error to
  /// a new [DoosErr]. Otherwise, returns a new [DoosOk] with the same value.
  Future<DoosResult<T, E2>> mapError<E2>(E2 Function(E) fn) =>
      then((result) => result.mapError(fn));

  /// Awaits this future, then, if this is a [DoosOk], returns the result of the
  /// given function. Otherwise, returns a new [DoosErr] with the same error.
  Future<DoosResult<T2, E>> andThen<T2>(DoosResult<T2, E> Function(T) fn) =>
      then((result) => result.andThen(fn));

  /// Awaits this future, then, if this is a [DoosErr], returns the result of
  /// the given function. Otherwise, returns a new [DoosOk] with the same value.
  Future<DoosResult<T, E2>> orElse<E2>(DoosResult<T, E2> Function(E) fn) =>
      then((result) => result.orElse(fn));
}

/// An annotation for methods that are redundant.
typedef Redundant = Deprecated;
