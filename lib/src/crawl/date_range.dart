/// Simple date range configuration for crawl jobs.
sealed class CrawlDateRange {
  const CrawlDateRange();

  /// Resolves this date range to actual start/end dates.
  ///
  /// [referenceDate] is used as the reference point for relative ranges
  /// (e.g., "current_month" resolves relative to this date).
  ({DateTime start, DateTime end}) resolve(DateTime referenceDate);
}

/// Integer format: last N days (backward compatibility).
class CrawlDateRangeDays extends CrawlDateRange {
  const CrawlDateRangeDays(this.days);

  final int days;

  @override
  ({DateTime start, DateTime end}) resolve(DateTime referenceDate) {
    final endDate = referenceDate;
    final startDate = endDate.subtract(Duration(days: days - 1));
    return (start: startDate, end: endDate);
  }
}

/// String shortcut: "today", "current_week", "current_month", "current_year".
class CrawlDateRangeShortcut extends CrawlDateRange {
  const CrawlDateRangeShortcut(this.shortcut);

  final String
  shortcut; // "today" | "current_week" | "current_month" | "current_year"

  @override
  ({DateTime start, DateTime end}) resolve(DateTime referenceDate) {
    switch (shortcut) {
      case 'today':
        // Just today - start and end both at start of day
        final startOfDay = DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day,
        );
        return (start: startOfDay, end: startOfDay);
      case 'current_week':
        final startOfWeek = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return (start: startOfWeek, end: endOfWeek);
      case 'current_month':
        final startOfMonth = DateTime(
          referenceDate.year,
          referenceDate.month,
        );
        final endOfMonth = DateTime(
          referenceDate.year,
          referenceDate.month + 1,
          0,
        ); // Last day of month
        return (start: startOfMonth, end: endOfMonth);
      case 'current_year':
        final startOfYear = DateTime(referenceDate.year);
        final endOfYear = DateTime(referenceDate.year, 12, 31);
        return (start: startOfYear, end: endOfYear);
      default:
        throw ArgumentError('Unknown shortcut: $shortcut');
    }
  }
}

/// Time unit back: days, weeks, or months.
class CrawlDateRangeTimeUnit extends CrawlDateRange {
  const CrawlDateRangeTimeUnit({
    this.days,
    this.weeks,
    this.months,
  });

  final int? days;
  final int? weeks;
  final int? months;

  @override
  ({DateTime start, DateTime end}) resolve(DateTime referenceDate) {
    final endDate = referenceDate;
    DateTime startDate;

    if (days != null) {
      startDate = endDate.subtract(Duration(days: days! - 1));
    } else if (weeks != null) {
      startDate = endDate.subtract(Duration(days: (weeks! * 7) - 1));
    } else if (months != null) {
      // Approximate months as 30 days (for simplicity)
      // More accurate would require handling month boundaries, but this is
      // acceptable for the use case
      startDate = endDate.subtract(Duration(days: (months! * 30) - 1));
    } else {
      throw StateError('TimeUnit must have one of: days, weeks, months');
    }

    return (start: startDate, end: endDate);
  }
}

/// Absolute date range: specific start and end dates.
class CrawlDateRangeAbsolute extends CrawlDateRange {
  const CrawlDateRangeAbsolute({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  @override
  ({DateTime start, DateTime end}) resolve(DateTime referenceDate) {
    // Ignore referenceDate for absolute ranges
    return (start: start, end: end);
  }
}
