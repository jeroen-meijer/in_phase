import 'package:clix/clix.dart';

/// A spinner line shown while a long-running task executes.
final class SpinnerSession {
  SpinnerSession(String message)
    : _message = message,
      _spinner = Spinner(message);

  String _message;
  final Spinner _spinner;
  var _finished = false;

  /// Whether [succeed] or [fail] has already been called.
  bool get isFinished => _finished;

  /// Updates the spinner text (animation continues on the same line).
  void updateMessage(String message) {
    _message = message;
    _spinner.update(message);
  }

  /// Marks the spinner line as successful.
  void succeed() {
    if (_finished) {
      return;
    }
    _finished = true;
    _spinner.complete(_message);
  }

  /// Marks the spinner line as failed.
  void fail() {
    if (_finished) {
      return;
    }
    _finished = true;
    _spinner.fail(_message);
  }
}

/// Runs [run] while showing [message] in a spinner.
///
/// Call [SpinnerSession.succeed] or [SpinnerSession.fail] from [run] when the
/// outcome is known before returning. When [run] returns without finishing the
/// session, the spinner is marked successful automatically. Uncaught errors
/// mark the spinner as failed and are rethrown.
Future<T> withSpinner<T>(
  String message,
  Future<T> Function(SpinnerSession session) run,
) async {
  final session = SpinnerSession(message);
  try {
    final result = await run(session);
    if (!session.isFinished) {
      session.succeed();
    }
    return result;
  } catch (_) {
    if (!session.isFinished) {
      session.fail();
    }
    rethrow;
  }
}
