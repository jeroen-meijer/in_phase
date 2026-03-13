import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/entities/entities.dart';

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
  static ({DateTime start, DateTime end}) resolve(
    CrawlFilters filters, {
    DateTime? referenceDate,
    DateTime? cliStartDate,
    DateTime? cliEndDate,
  }) {
    // Validate that both date_range and added_between_days aren't set
    // ignore: deprecated_member_use_from_same_package
    if (filters.dateRange != null && filters.addedBetweenDays != null) {
      throw ArgumentError(
        'Cannot specify both date_range and added_between_days. '
        'Use date_range only (added_between_days is deprecated).',
      );
    }

    // Use CLI end date as reference if provided, otherwise use referenceDate
    // or now
    final effectiveReference = cliEndDate ?? referenceDate ?? DateTime.now();

    // Handle deprecated added_between_days for backward compat
    // ignore: deprecated_member_use_from_same_package
    if (filters.dateRange == null && filters.addedBetweenDays != null) {
      final resolved = _resolveDays(
        // ignore: deprecated_member_use_from_same_package
        filters.addedBetweenDays!,
        effectiveReference,
      );
      // Apply CLI start date override if provided
      if (cliStartDate != null) {
        return (
          start: cliStartDate.subtract(const Duration(days: 1)),
          end: resolved.end,
        );
      }
      return resolved;
    }

    // Use new dateRange field
    final resolved =
        filters.dateRange?.resolve(effectiveReference) ??
        _resolveDays(7, effectiveReference); // default fallback

    // Apply CLI start date override if provided
    if (cliStartDate != null) {
      return (
        start: cliStartDate.subtract(const Duration(days: 1)),
        end: resolved.end,
      );
    }

    return resolved;
  }

  /// Validates a CrawlFilters object and throws descriptive errors.
  static void validate(CrawlFilters filters) {
    // Check for both fields set
    // ignore: deprecated_member_use_from_same_package
    if (filters.dateRange != null && filters.addedBetweenDays != null) {
      throw ArgumentError(
        'Cannot specify both date_range and added_between_days in filters. '
        'Use date_range only (added_between_days is deprecated).',
      );
    }

    // Validate dateRange if present
    if (filters.dateRange != null) {
      _validateDateRange(filters.dateRange!);
    }

    // Validate added_between_days if present (deprecated but still validate)
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
            'date_range start date (${formatDate(start)}) must be before '
            'or equal to end date (${formatDate(end)})',
          );
        }
    }
  }

  /// Helper to resolve days back (for backward compatibility).
  static ({DateTime start, DateTime end}) _resolveDays(
    int days,
    DateTime referenceDate,
  ) {
    final endDate = referenceDate;
    final startDate = endDate.subtract(Duration(days: days - 1));
    return (start: startDate, end: endDate);
  }
}
