import 'package:in_phase/src/crawl/date_range.dart';
import 'package:in_phase/src/crawl/date_utils.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:simple_date/simple_date.dart';

/// Resolves date range configurations to actual start/end dates.
class DateRangeResolver {
  /// Resolves a CrawlFilters object to start/end dates.
  ///
  /// [referenceDate] is used as the reference point for relative ranges
  /// (e.g., "current_month" resolves relative to this date).
  /// Typically this is DateTime.now() or --end-date if provided.
  ///
  /// [cliStartDate] and [cliEndDate] are optional CLI flag overrides.
  /// - If [cliEndDate] is provided, it replaces [referenceDate] for
  ///   relative calculations
  /// - If [cliStartDate] is provided, it overrides the calculated start date
  static ({SimpleDate start, SimpleDate end}) resolve(
    CrawlFilters filters, {
    DateTime? referenceDate,
    DateTime? cliStartDate,
    DateTime? cliEndDate,
  }) {
    // ignore: deprecated_member_use_from_same_package
    if (filters.dateRange != null && filters.addedBetweenDays != null) {
      throw ArgumentError(
        'Cannot specify both date_range and added_between_days. '
        'Use date_range only (added_between_days is deprecated).',
      );
    }

    final effectiveReference = cliEndDate ?? referenceDate ?? DateTime.now();

    // ignore: deprecated_member_use_from_same_package
    if (filters.dateRange == null && filters.addedBetweenDays != null) {
      final resolved = _resolveDays(
        // ignore: deprecated_member_use_from_same_package
        filters.addedBetweenDays!,
        effectiveReference,
      );
      if (cliStartDate != null) {
        return (
          start: simpleDateFromLocalDateTime(cliStartDate).subtract(days: 1),
          end: resolved.end,
        );
      }
      return resolved;
    }

    final resolved =
        filters.dateRange?.resolve(effectiveReference) ??
        _resolveDays(7, effectiveReference);

    if (cliStartDate != null) {
      return (
        start: simpleDateFromLocalDateTime(cliStartDate).subtract(days: 1),
        end: resolved.end,
      );
    }

    return resolved;
  }

  /// Validates a CrawlFilters object and throws descriptive errors.
  static void validate(CrawlFilters filters) {
    // ignore: deprecated_member_use_from_same_package
    if (filters.dateRange != null && filters.addedBetweenDays != null) {
      throw ArgumentError(
        'Cannot specify both date_range and added_between_days in filters. '
        'Use date_range only (added_between_days is deprecated).',
      );
    }

    if (filters.dateRange != null) {
      _validateDateRange(filters.dateRange!);
    }

    // ignore: deprecated_member_use_from_same_package
    if (filters.addedBetweenDays != null) {
      // ignore: deprecated_member_use_from_same_package
      if (filters.addedBetweenDays! <= 0) {
        throw ArgumentError(
          'added_between_days must be positive, '
          // ignore: deprecated_member_use_from_same_package
          'got ${filters.addedBetweenDays}',
        );
      }
    }
  }

  static void _validateDateRange(CrawlDateRange range) {
    switch (range) {
      case CrawlDateRangeDays(:final days):
        if (days <= 0) {
          throw ArgumentError(
            'date_range (integer) must be positive, got $days',
          );
        }
      case CrawlDateRangeShortcut(:final shortcut):
        if (![
          'today',
          'current_week',
          'current_month',
          'current_year',
        ].contains(shortcut)) {
          throw ArgumentError(
            'Invalid date_range shortcut: "$shortcut". '
            'Must be one of: "today", "current_week", "current_month", '
            '"current_year"',
          );
        }
      case CrawlDateRangeTimeUnit(:final days, :final weeks, :final months):
        final count =
            (days != null ? 1 : 0) +
            (weeks != null ? 1 : 0) +
            (months != null ? 1 : 0);
        if (count == 0) {
          throw ArgumentError(
            'date_range object must specify exactly one of: days, weeks, '
            'or months',
          );
        }
        if (count > 1) {
          final found = <String>[];
          if (days != null) found.add('days');
          if (weeks != null) found.add('weeks');
          if (months != null) found.add('months');
          throw ArgumentError(
            'date_range object can only specify one time unit. '
            'Found: ${found.join(', ')}',
          );
        }
        if (days != null && days <= 0) {
          throw ArgumentError('date_range.days must be positive, got $days');
        }
        if (weeks != null && weeks <= 0) {
          throw ArgumentError('date_range.weeks must be positive, got $weeks');
        }
        if (months != null && months <= 0) {
          throw ArgumentError(
            'date_range.months must be positive, got $months',
          );
        }
      case CrawlDateRangeAbsolute(:final start, :final end):
        if (start.isAfter(end)) {
          throw ArgumentError(
            'date_range start date (${formatSimpleDate(start)}) must be before '
            'or equal to end date (${formatSimpleDate(end)})',
          );
        }
    }
  }

  static ({SimpleDate start, SimpleDate end}) _resolveDays(
    int days,
    DateTime referenceDate,
  ) {
    final endDay = simpleDateFromLocalDateTime(referenceDate);
    final startDate = inclusiveCalendarStartForLastNDays(endDay, days);
    return (start: startDate, end: endDay);
  }
}
