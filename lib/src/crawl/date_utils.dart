/// Utilities for parsing and working with Spotify release dates.
library;

import 'package:simple_date/simple_date.dart';

/// Parses a Spotify release date string to a [SimpleDate] (local calendar).
///
/// Spotify returns dates in different formats:
/// - Full date: 'YYYY-MM-DD' (e.g., '2024-01-15')
/// - Year-month: 'YYYY-MM' (e.g., '2024-01') → first of month
/// - Year only: 'YYYY' (e.g., '2024') → Jan 1
///
/// Throws [FormatException] if the date string cannot be parsed.
SimpleDate parseSpotifyReleaseDate(String releaseDateStr) {
  if (releaseDateStr.isEmpty) {
    throw const FormatException('Release date string is empty');
  }

  if (releaseDateStr.length == 10) {
    try {
      return SimpleDate.fromDateTime(DateTime.parse(releaseDateStr));
    } catch (_) {
      throw FormatException('Could not parse full date: $releaseDateStr');
    }
  }

  if (releaseDateStr.length == 7 && releaseDateStr[4] == '-') {
    try {
      final parts = releaseDateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return SimpleDate(year, month);
    } catch (_) {
      throw FormatException('Could not parse year-month date: $releaseDateStr');
    }
  }

  if (releaseDateStr.length == 4) {
    try {
      final year = int.parse(releaseDateStr);
      return SimpleDate(year);
    } catch (_) {
      throw FormatException('Could not parse year-only date: $releaseDateStr');
    }
  }

  throw FormatException('Unsupported date format: $releaseDateStr');
}

/// Local calendar date for an instant in the local timezone.
SimpleDate simpleDateFromLocalDateTime(DateTime d) =>
    SimpleDate.fromDateTime(d);

/// Inclusive calendar start for "last [n] days" ending on [end]'s date.
///
/// For example, last 7 days ending 2026-04-03 is 2026-03-28 … 2026-04-03.
SimpleDate inclusiveCalendarStartForLastNDays(SimpleDate end, int n) {
  if (n <= 0) {
    throw ArgumentError.value(n, 'n', 'must be positive');
  }
  return end.subtract(days: n - 1);
}

extension SimpleDateCrawlX on SimpleDate {
  /// Range `(cutoff, end]`: exclusive [cutoff], inclusive [end] — for release
  /// dates (midnight per day).
  bool isInExclusiveInclusiveRange(SimpleDate cutoff, SimpleDate end) =>
      isAfter(cutoff) && !isAfter(end);
}

/// Whether [day] lies in the inclusive calendar range [[start], [end]].
///
/// Use for playlist **added** timestamps interpreted by local calendar day.
bool isCalendarDayInInclusiveRange(
  SimpleDate day,
  SimpleDate start,
  SimpleDate end,
) => !day.isBefore(start) && !day.isAfter(end);

/// Gets the ISO week number for a given date.
///
/// Returns a value from 1 to 53.
int getWeekNumber(SimpleDate date) {
  final dt = date.toDateTime();
  final firstDayOfYear = DateTime(dt.year);

  final daysSinceYearStart = dt.difference(firstDayOfYear).inDays;

  final weekNumber = ((daysSinceYearStart + firstDayOfYear.weekday) / 7).ceil();

  return weekNumber.clamp(1, 53);
}

/// Formats a [DateTime] as YYYY-MM-DD (local calendar components).
String formatDate(DateTime date) =>
    formatSimpleDate(simpleDateFromLocalDateTime(date));

/// Formats a [SimpleDate] as YYYY-MM-DD (same as [SimpleDate.toString]).
String formatSimpleDate(SimpleDate date) => date.toString();
