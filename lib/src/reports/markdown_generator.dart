import 'package:intl/intl.dart';

/// Utilities for generating markdown content.
class MarkdownGenerator {
  /// Creates a markdown header of the specified level.
  static String header(String text, {int level = 1}) {
    if (level < 1 || level > 6) {
      throw ArgumentError('Header level must be between 1 and 6');
    }
    return '${'#' * level} $text\n';
  }

  /// Creates a markdown table from headers and rows.
  ///
  /// Example:
  /// ```dart
  /// table(
  ///   headers: ['Name', 'Age'],
  ///   rows: [
  ///     ['Alice', '25'],
  ///     ['Bob', '30'],
  ///   ],
  /// )
  /// ```
  static String table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (headers.isEmpty) {
      throw ArgumentError('Headers cannot be empty');
    }

    final buffer = StringBuffer()
      // Write header row
      ..write('| ${headers.join(' | ')} |\n')
      // Write separator row
      ..write('| ${headers.map((_) => '---').join(' | ')} |\n');

    // Write data rows
    for (final row in rows) {
      // Escape pipe characters in cells
      final escapedRow = row.map((cell) => cell.replaceAll('|', r'\|'));
      buffer.write('| ${escapedRow.join(' | ')} |\n');
    }

    return buffer.toString();
  }

  /// Creates a markdown list from items.
  static String list(List<String> items, {bool ordered = false}) {
    final buffer = StringBuffer();
    for (var i = 0; i < items.length; i++) {
      final index = i + 1;
      final prefix = ordered ? '$index.' : '-';
      buffer.write('$prefix ${items[i]}\n');
    }
    return buffer.toString();
  }

  /// Creates a markdown blockquote.
  static String blockquote(String text) {
    return '${text.split('\n').map((line) => '> $line').join('\n')}\n';
  }

  /// Creates a markdown code block with optional language.
  static String codeBlock(String code, {String? language}) {
    return '```${language ?? ''}\n$code\n```\n';
  }

  /// Creates inline code.
  static String code(String text) => '`$text`';

  /// Creates bold text.
  static String bold(String text) => '**$text**';

  /// Creates italic text.
  static String italic(String text) => '*$text*';

  /// Creates a markdown link.
  static String link(String text, String url) => '[$text]($url)';

  /// Creates a horizontal rule.
  static String horizontalRule() => '---\n';

  /// Formats a date for display.
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats a datetime for display.
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Formats a duration for display.
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Escapes markdown special characters.
  static String escape(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('*', r'\*')
        .replaceAll('_', r'\_')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)')
        .replaceAll('#', r'\#')
        .replaceAll('+', r'\+')
        .replaceAll('-', r'\-')
        .replaceAll('.', r'\.')
        .replaceAll('!', r'\!')
        .replaceAll('`', r'\`');
  }
}
