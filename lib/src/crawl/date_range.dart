import 'package:in_phase/src/crawl/date_utils.dart';
import 'package:simple_date/simple_date.dart';

/// Simple date range configuration for crawl jobs.
sealed class CrawlDateRange {
  const CrawlDateRange();

  /// Resolves this date range to actual start/end dates.
  ///
  /// [referenceDate] is used as the reference point for relative ranges
  /// (e.g., "current_month" resolves relative to this date).
  ({SimpleDate start, SimpleDate end}) resolve(DateTime referenceDate);
}

/// Integer format: last N days (backward compatibility).
class CrawlDateRangeDays extends CrawlDateRange {
  const CrawlDateRangeDays(this.days);

  final int days;

  @override
  ({SimpleDate start, SimpleDate end}) resolve(DateTime referenceDate) {
    final endDay = simpleDateFromLocalDateTime(referenceDate);
    final startDate = inclusiveCalendarStartForLastNDays(endDay, days);
    return (start: startDate, end: endDay);
  }
}

/// String shortcut: "today", "current_week", "current_month", "current_year".
class CrawlDateRangeShortcut extends CrawlDateRange {
  const CrawlDateRangeShortcut(this.shortcut);

  final String
  shortcut; // "today" | "current_week" | "current_month" | "current_year"

  @override
  ({SimpleDate start, SimpleDate end}) resolve(DateTime referenceDate) {
    switch (shortcut) {
      case 'today':
        final startOfDay = simpleDateFromLocalDateTime(referenceDate);
        return (start: startOfDay, end: startOfDay);
      case 'current_week':
        final d = simpleDateFromLocalDateTime(referenceDate);
        final startOfWeek = d.subtract(days: d.weekday - 1);
        final endOfWeek = startOfWeek.add(days: 6);
        return (start: startOfWeek, end: endOfWeek);
      case 'current_month':
        final startOfMonth = SimpleDate(
          referenceDate.year,
          referenceDate.month,
        );
        final endOfMonth = SimpleDate(
          referenceDate.year,
          referenceDate.month + 1,
          0,
        );
        return (start: startOfMonth, end: endOfMonth);
      case 'current_year':
        final startOfYear = SimpleDate(referenceDate.year);
        final endOfYear = SimpleDate(referenceDate.year, 12, 31);
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
  ({SimpleDate start, SimpleDate end}) resolve(DateTime referenceDate) {
    final endDay = simpleDateFromLocalDateTime(referenceDate);
    SimpleDate startDate;

    if (days != null) {
      startDate = inclusiveCalendarStartForLastNDays(endDay, days!);
    } else if (weeks != null) {
      startDate = inclusiveCalendarStartForLastNDays(endDay, weeks! * 7);
    } else if (months != null) {
      startDate = endDay.subtract(months: months!);
    } else {
      throw StateError('TimeUnit must have one of: days, weeks, months');
    }

    return (start: startDate, end: endDay);
  }
}

/// Absolute date range: specific start and end dates.
class CrawlDateRangeAbsolute extends CrawlDateRange {
  const CrawlDateRangeAbsolute({
    required this.start,
    required this.end,
  });

  final SimpleDate start;
  final SimpleDate end;

  @override
  ({SimpleDate start, SimpleDate end}) resolve(DateTime referenceDate) {
    return (start: start, end: end);
  }
}
