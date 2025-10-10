/// Utilities for parsing and working with Spotify release dates.
library;

/// Parses a Spotify release date string.
///
/// Spotify returns dates in different formats:
/// - Full date: 'YYYY-MM-DD' (e.g., '2024-01-15')
/// - Year-month: 'YYYY-MM' (e.g., '2024-01')
/// - Year only: 'YYYY' (e.g., '2024')
///
/// Missing parts default to: month=1, day=1, time=00:00:00.
///
/// Throws [FormatException] if the date string cannot be parsed.
DateTime parseSpotifyReleaseDate(String releaseDateStr) {
  if (releaseDateStr.isEmpty) {
    throw const FormatException('Release date string is empty');
  }

  // Try full date format: YYYY-MM-DD
  if (releaseDateStr.length == 10) {
    try {
      return DateTime.parse(releaseDateStr);
    } catch (_) {
      throw FormatException('Could not parse full date: $releaseDateStr');
    }
  }

  // Try year-month format: YYYY-MM
  if (releaseDateStr.length == 7 && releaseDateStr[4] == '-') {
    try {
      final parts = releaseDateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateTime(year, month);
    } catch (_) {
      throw FormatException('Could not parse year-month date: $releaseDateStr');
    }
  }

  // Try year-only format: YYYY
  if (releaseDateStr.length == 4) {
    try {
      final year = int.parse(releaseDateStr);
      return DateTime(year);
    } catch (_) {
      throw FormatException('Could not parse year-only date: $releaseDateStr');
    }
  }

  throw FormatException('Unsupported date format: $releaseDateStr');
}

extension DateTimeUtils on DateTime {
  /// Checks if a date is within the specified range.
  ///
  /// The range is exclusive on the lower bound and inclusive on the upper
  /// bound: `(cutoffDate, endDate]`
  ///
  /// This means:
  /// - A track added exactly at cutoffDate is NOT included
  /// - A track added exactly at endDate IS included
  bool isInRange(
    DateTime cutoffDate,
    DateTime endDate,
  ) {
    return isAfter(cutoffDate) &&
        (isBefore(endDate) || isAtSameMomentAs(endDate));
  }
}

/// Gets the ISO week number for a given date.
///
/// Returns a value from 1 to 53.
int getWeekNumber(DateTime date) {
  // Get the first day of the year
  final firstDayOfYear = DateTime(date.year);

  // Calculate the number of days since the start of the year
  final daysSinceYearStart = date.difference(firstDayOfYear).inDays;

  // Calculate the week number (ISO 8601)
  // We add 1 because the first day is week 1
  final weekNumber = ((daysSinceYearStart + firstDayOfYear.weekday) / 7).ceil();

  return weekNumber.clamp(1, 53);
}

/// Formats a date as YYYY-MM-DD.
String formatDate(DateTime date) {
  return date.toIso8601String().split('T')[0];
}
