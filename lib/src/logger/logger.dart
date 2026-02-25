import 'package:dcli/dcli.dart';
import 'package:in_phase/src/misc/misc.dart';

final log = _Logger();

enum _LogLevel {
  debug,
  info,
  warning,
  error,
}

class _Logger {
  _Logger();

  /// When enabled, will add the date and time to the log message and allows
  /// debug level logs to be printed.
  bool debugMode = false;

  DateTime? _lastLogTime;

  void _log(_LogLevel logLevel, Object? object) {
    if (logLevel == _LogLevel.debug && !debugMode) {
      return;
    }

    final color = switch (logLevel) {
      _LogLevel.debug => (String line) => grey(line, level: 0),
      _LogLevel.info => null,
      _LogLevel.warning => yellow,
      _LogLevel.error => red,
    };

    late final String deserializedObject;

    switch (object) {
      case final Map<dynamic, dynamic> map:
        try {
          final encoded = jsonEncodeWithIndent(map);
          deserializedObject = '\n$encoded';
        } catch (e) {
          deserializedObject = '\n$map';
        }
      case final object:
        deserializedObject = object.toString();
    }

    final deserializedObjectLines = deserializedObject.split('\n');
    final isMultiLine = deserializedObjectLines.length > 1;

    var message = deserializedObjectLines
        .map((line) => isMultiLine ? '  $line' : line)
        .map((line) => color?.call(line) ?? line)
        .join('\n');
    if (debugMode) {
      final now = DateTime.now();
      final dateTimeIso = now.toIso8601String();
      final time = dateTimeIso.substring(
        dateTimeIso.indexOf('T') + 1,
        dateTimeIso.indexOf('.'),
      );

      const timeDiffDigits = 5;
      final timeDiff = switch (_lastLogTime) {
        null => null,
        final lastLogTime => now.difference(lastLogTime).inMilliseconds,
      };
      _lastLogTime = now;

      final timeDiffString =
          // ignore: lines_longer_than_80_chars
          '(+${timeDiff?.toString().padLeft(timeDiffDigits) ?? (' ' * timeDiffDigits)} ms)';

      final leading = [
        grey('[$time]', level: 0.7),
        if (timeDiff != null)
          grey(timeDiffString, level: 0)
        else
          ' ' * timeDiffString.length,
      ];

      message = [
        leading.join(' '),
        message,
      ].join(isMultiLine ? ' ↴\n' : ' ');
    }

    raw(message);
  }

  /// Prints the object at debug level.
  void debug(Object? object) {
    _log(_LogLevel.debug, object);
  }

  /// Prints the object at info level.
  void info(Object? object) {
    _log(_LogLevel.info, object);
  }

  /// Prints the object at warning level.
  void warning(Object? object) {
    _log(_LogLevel.warning, object);
  }

  /// Prints the object at error level.
  void error(Object? object) {
    _log(_LogLevel.error, object);
  }

  /// Prints the object without any formatting or coloring.
  void raw(Object? object) {
    // ignore: avoid_print
    print(object);
  }
}
