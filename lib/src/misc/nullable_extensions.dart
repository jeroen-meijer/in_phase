/// Extensions for working with nullable types.
///
/// Provides utility methods for safely operating on nullable values without
/// explicit null checks.
extension NullableExtensions<T> on T? {
  /// Applies a transformation function to a value if it is non-null.
  ///
  /// This is a functional-style alternative to null-aware operators and
  /// pattern matching. It allows chaining transformations on nullable values
  /// in a concise way.
  ///
  /// Example:
  /// ```dart
  /// final result = nullableValue
  ///   .let((value) => value * 2)
  ///   .let((doubled) => doubled.toString());
  /// ```
  ///
  /// Returns `null` if the value is `null`, otherwise returns the result of
  /// applying [f] to the value.
  R? let<R>(R Function(T value) f) => switch (this) {
    final value? => f(value),
    _ => null,
  };

  /// Returns this value if it is non-null, otherwise returns the given default
  /// value.
  T? or(T defaultValue) => this ?? defaultValue;

  /// Returns this value if it is non-null, otherwise returns the result of
  /// applying [f] to the value.
  T? orElse(T Function() f) => this ?? f();
}
