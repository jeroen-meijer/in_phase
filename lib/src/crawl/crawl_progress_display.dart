import 'dart:async';
import 'dart:io' as io;

import 'package:dcli/dcli.dart';

/// Margin to leave at bottom of terminal for other output.
const int _crawlProgressDisplayMargin = 4;

/// Max lines for the "recently completed" section.
const int _recentCompletedCount = 5;

/// In-place progress display for crawl collection.
///
/// Shows a header with overall progress, a "recently completed" section, and
/// slots for currently loading sources. When a source completes, it appears
/// in the recent section and its slot is reused for the next pending source.
/// This avoids scrolling with many sources.
///
/// Shows blue spinner while loading, green checkmark when done.
/// Uses identifier until display name is resolved.
/// Falls back to no-op when not a TTY.
class CrawlProgressDisplay {
  CrawlProgressDisplay({
    required List<String> identifiers,
    io.Stdout? stdout,
  })  : _identifiers = List.of(identifiers),
        _stdout = stdout ?? io.stdout,
        _displayNames = List.filled(identifiers.length, null),
        _completed = List.filled(identifiers.length, false),
        _trackCounts = List.filled(identifiers.length, 0),
        _hasError = List.filled(identifiers.length, false),
        _layout = _computeLayout(stdout ?? io.stdout, identifiers.length),
        _slotToSource = List.filled(
          _computeLayout(stdout ?? io.stdout, identifiers.length).inProgressSlots,
          -1,
        ),
        _sourceToSlot = List.filled(identifiers.length, -1);

  static _Layout _computeLayout(io.Stdout stdout, int sourceCount) {
    if (sourceCount == 0) {
      return _Layout(recentCount: 0, inProgressSlots: 0, totalLines: 0);
    }
    final lines = stdout.hasTerminal ? stdout.terminalLines : 0;
    final available = lines - _crawlProgressDisplayMargin;
    if (available <= 0) {
      return _Layout(recentCount: 0, inProgressSlots: 0, totalLines: 0);
    }
    final recentCount =
        available > 4 ? _recentCompletedCount.clamp(0, available - 4) : 0;
    final inProgressSlots = (available - 1 - recentCount - 1)
        .clamp(1, sourceCount);
    final totalLines = 1 + recentCount + 1 + inProgressSlots;
    return _Layout(
      recentCount: recentCount,
      inProgressSlots: inProgressSlots,
      totalLines: totalLines,
    );
  }

  final io.Stdout _stdout;
  final List<String> _identifiers;
  final List<String?> _displayNames;
  final List<bool> _completed;
  final List<int> _trackCounts;
  final List<bool> _hasError;
  final _Layout _layout;
  final List<int> _slotToSource;
  final List<int> _sourceToSlot;
  final List<int> _recentlyCompleted = [];
  var _nextSourceToAssign = 0;

  Timer? _redrawTimer;
  var _spinnerFrame = 0;
  var _isFirstRedraw = true;
  var _isStarted = false;

  static const _spinnerFrames = ['|', '/', '-', '\\'];
  static const _eraseLine = '\x1b[2K';
  static const _eraseToEnd = '\x1b[0J';
  static const _tagWidth = 22;

  static String _shortId(String id, {int maxLen = 12}) =>
      id.length > maxLen ? id.substring(0, maxLen) : id;

  /// Whether the display is active (TTY and started).
  bool get isActive => _isStarted && _stdout.hasTerminal;

  /// Creates a reporter for source [index] to receive display name updates.
  CrawlProgressReporter reporterFor(int index) =>
      _CrawlProgressReporterImpl(this, index);

  /// Updates the display name for source [index]. Call when the name is resolved.
  void setDisplayName(int index, String name) {
    if (index >= 0 && index < _displayNames.length) {
      _displayNames[index] = name;
    }
  }

  /// Marks source [index] as done with [trackCount] tracks.
  /// Adds to recently completed and reuses its slot for the next pending source.
  void setDone(int index, int trackCount) {
    if (index < 0 || index >= _completed.length) return;

    _completed[index] = true;
    _trackCounts[index] = trackCount;

    _addToRecentlyCompleted(index);
    _reassignSlot(index);
  }

  /// Marks source [index] as failed.
  /// Adds to recently completed and reuses its slot for the next pending source.
  void setError(int index) {
    if (index < 0 || index >= _hasError.length) return;

    _hasError[index] = true;
    _completed[index] = true;

    _addToRecentlyCompleted(index);
    _reassignSlot(index);
  }

  void _addToRecentlyCompleted(int index) {
    _recentlyCompleted.insert(0, index);
    if (_recentlyCompleted.length > _layout.recentCount) {
      _recentlyCompleted.length = _layout.recentCount;
    }
  }

  void _reassignSlot(int completedSourceIndex) {
    final slot = _sourceToSlot[completedSourceIndex];
    if (slot < 0) return;

    _sourceToSlot[completedSourceIndex] = -1;

    if (_nextSourceToAssign < _identifiers.length) {
      final next = _nextSourceToAssign++;
      _slotToSource[slot] = next;
      _sourceToSlot[next] = slot;
    }
    // When no next source, keep slot showing completed item so it displays ✓
  }

  /// Starts the display. Call before collection begins.
  void start() {
    if (!_stdout.hasTerminal ||
        _identifiers.isEmpty ||
        _layout.totalLines == 0) return;

    _isStarted = true;

    // Initial slot assignment: first N sources get in-progress slots
    final slotCount = _layout.inProgressSlots;
    for (var s = 0; s < slotCount && s < _identifiers.length; s++) {
      _slotToSource[s] = s;
      _sourceToSlot[s] = s;
    }
    _nextSourceToAssign = slotCount.clamp(0, _identifiers.length);

    _stdout.write('\x1b[?25l'); // Hide cursor

    _drawAll();

    _redrawTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _redraw();
      _isFirstRedraw = false;
      _spinnerFrame = (_spinnerFrame + 1) % _spinnerFrames.length;
    });
  }

  /// Stops the display. Call when all collection is complete.
  void stop() {
    _redrawTimer?.cancel();
    _redrawTimer = null;

    if (_isStarted && _stdout.hasTerminal) {
      _redraw();
      _stdout.write('\n');
      _stdout.write('\x1b[?25h'); // Show cursor
    }
    _isStarted = false;
  }

  void _drawAll() {
    final completedCount = _completed.where((c) => c).length;
    _stdout.writeln(_formatHeader(completedCount));

    for (var r = 0; r < _layout.recentCount; r++) {
      _stdout.writeln(_formatRecentlyCompletedLine(r));
    }

    _stdout.writeln('${'─' * (_tagWidth + 15)}');

    for (var s = 0; s < _layout.inProgressSlots; s++) {
      _stdout.writeln(_formatSlot(s));
    }
  }

  void _redraw() {
    if (!_isStarted || !_stdout.hasTerminal) return;

    if (_isFirstRedraw) {
      _stdout.write(_cursorUp(_layout.totalLines));
    } else {
      _stdout.write('\r');
      _stdout.write(_cursorUp(_layout.totalLines - 1));
    }
    _stdout.write(_eraseToEnd);

    final completedCount = _completed.where((c) => c).length;
    _stdout.write(_eraseLine);
    _stdout.writeln(_formatHeader(completedCount));

    for (var r = 0; r < _layout.recentCount; r++) {
      _stdout.write(_eraseLine);
      _stdout.writeln(_formatRecentlyCompletedLine(r));
    }

    _stdout.write(_eraseLine);
    _stdout.writeln('${'─' * (_tagWidth + 15)}');

    for (var s = 0; s < _layout.inProgressSlots; s++) {
      _stdout.write(_eraseLine);
      _stdout.write(_formatSlot(s));
      if (s < _layout.inProgressSlots - 1) _stdout.writeln();
    }
  }

  String _formatHeader(int completedCount) {
    return 'Crawl (${green('$completedCount')}/${_identifiers.length} complete)';
  }

  String _formatRecentlyCompletedLine(int recentIndex) {
    if (recentIndex >= _recentlyCompleted.length) {
      return ''.padRight(_tagWidth + 15);
    }
    final sourceIndex = _recentlyCompleted[recentIndex];
    return _formatCompletedSource(sourceIndex);
  }

  String _formatCompletedSource(int sourceIndex) {
    final label = (_displayNames[sourceIndex] ?? _shortId(_identifiers[sourceIndex]))
        .padRight(_tagWidth);
    if (_hasError[sourceIndex]) {
      return '$label ${red('\u2717')} Error';
    }
    final count = _trackCounts[sourceIndex];
    final countStr = count == 1 ? '1 track' : '${count} tracks';
    return '$label ${green('\u2713')} $countStr';
  }

  String _formatSlot(int slot) {
    final sourceIndex = _slotToSource[slot];
    if (sourceIndex < 0) {
      return ''.padRight(_tagWidth + 15);
    }
    if (_completed[sourceIndex]) {
      return _formatCompletedSource(sourceIndex);
    }
    final label = (_displayNames[sourceIndex] ?? _shortId(_identifiers[sourceIndex]))
        .padRight(_tagWidth);
    final frame = _spinnerFrames[_spinnerFrame];
    return '$label ${blue(frame)} Fetching...';
  }

  static String _cursorUp(int n) => '\x1b[${n}A';
}

class _Layout {
  _Layout({
    required this.recentCount,
    required this.inProgressSlots,
    required this.totalLines,
  });

  final int recentCount;
  final int inProgressSlots;
  final int totalLines;
}

/// Reporter for a single crawl source. Pass to [TrackCollector] to receive
/// display name updates.
abstract class CrawlProgressReporter {
  void setDisplayName(String name);
}

class _CrawlProgressReporterImpl implements CrawlProgressReporter {
  _CrawlProgressReporterImpl(this._display, this._index);

  final CrawlProgressDisplay _display;
  final int _index;

  @override
  void setDisplayName(String name) {
    _display.setDisplayName(_index, name);
  }
}
