import 'package:rkdb_dart/src/crawl/date_utils.dart';
import 'package:rkdb_dart/src/entities/entities.dart';

/// Valid template variables for playlist names and descriptions.
enum TemplateVariable {
  // Date and time variables
  weekNum('week_num'),
  date('date'),
  month('month'),
  year('year'),
  timestamp('timestamp'),

  // Enhanced date variables
  monthNum('month_num'),
  monthName('month_name'),
  monthNameShort('month_name_short'),
  quarter('quarter'),
  yearShort('year_short'),

  // Week variables
  weekStartDate('week_start_date'),
  weekEndDate('week_end_date'),

  // Date range variables
  dateRangeStartDate('date_range_start_date'),
  dateRangeEndDate('date_range_end_date'),
  dateRangeDays('date_range_days'),
  dateRangeStartShort('date_range_start_short'),
  dateRangeEndShort('date_range_end_short'),
  dateRangeMonth('date_range_month'),
  dateRangeCrossMonth('date_range_cross_month'),

  // Format variables
  dateFormatYYYYMMDD('date_format_YYYY_MM_DD'),
  dateFormatDDMMYYYY('date_format_DD_MM_YYYY'),
  dateFormatMmmDD('date_format_MMM_DD'),
  timeFormatHHMM('time_format_HH_MM'),

  // Real date variables (current date)
  realDate('real_date'),
  realYear('real_year'),
  realMonth('real_month'),
  realMonthNum('real_month_num'),
  realYearShort('real_year_short'),
  realWeekNum('real_week_num'),
  realDay('real_day'),
  realDayName('real_day_name'),
  realDayNameShort('real_day_name_short'),
  realTimestamp('real_timestamp'),
  realWeekStartDate('real_week_start_date'),
  realWeekEndDate('real_week_end_date'),

  // Real time and datetime variables
  realTime('real_time'), // HH:MM format
  realTimeWithSeconds('real_time_with_seconds'), // HH:MM:SS format
  realDateTime('real_datetime'), // YYYY-MM-DD HH:MM format
  realDateTimeFull('real_datetime_full'), // YYYY-MM-DD HH:MM:SS format

  // Content statistics
  trackCount('track_count'),
  sourceCount('source_count'),

  // Job source counts (from configuration)
  jobPlaylistCount('job_playlist_count'),
  jobArtistCount('job_artist_count'),
  jobLabelCount('job_label_count'),

  // Real content counts (from actual tracks)
  realArtistCount('real_artist_count'),
  realAlbumCount('real_album_count'),
  realPlaylistCount('real_playlist_count'),
  realArtistSourceCount('real_artist_source_count'),
  realLabelSourceCount('real_label_source_count'),

  // Legacy aliases (for backward compatibility)
  playlistCount('playlist_count'), // same as job_playlist_count
  artistCount('artist_count'), // same as job_artist_count
  labelCount('label_count'), // same as job_label_count

  // Job and configuration variables
  jobName('job_name'),
  jobNamePretty('job_name_pretty'),
  inputSources('input_sources');

  const TemplateVariable(this.placeholder);

  final String placeholder;

  /// Parses a placeholder string to a [TemplateVariable].
  static TemplateVariable? tryParse(String placeholder) {
    for (final variable in TemplateVariable.values) {
      if (variable.placeholder == placeholder) {
        return variable;
      }
    }
    return null;
  }
}

/// Template engine for rendering playlist names and descriptions.
class TemplateEngine {
  const TemplateEngine();

  /// Pattern to match template variables in the form {variable_name}.
  static final _placeholderPattern = RegExp(r'\{([^}]+)\}');

  /// Renders a template string with the given context.
  ///
  /// Throws [FormatException] if the template contains invalid placeholders.
  String render(
    String template, {
    required CrawlJob job,
    required DateTime cutoffDate,
    required DateTime endDate,
    required int trackCount,
    required int realArtistCount,
    required int realAlbumCount,
    required int realPlaylistCount,
    required int realArtistSourceCount,
    required int realLabelCount,
  }) {
    final context = _TemplateContext(
      job: job,
      cutoffDate: cutoffDate,
      endDate: endDate,
      trackCount: trackCount,
      realArtistCount: realArtistCount,
      realAlbumCount: realAlbumCount,
      realPlaylistCount: realPlaylistCount,
      realArtistSourceCount: realArtistSourceCount,
      realLabelCount: realLabelCount,
    );

    return template.replaceAllMapped(_placeholderPattern, (match) {
      final placeholder = match.group(1)!;
      final variable = TemplateVariable.tryParse(placeholder);

      if (variable == null) {
        final validVars = TemplateVariable.values
            .map((v) => '{${v.placeholder}}')
            .join(', ');
        throw FormatException(
          'Invalid template variable: {$placeholder}\n'
          'Valid variables are: $validVars',
        );
      }

      return _resolveVariable(variable, context);
    });
  }

  /// Resolves a template variable to its value.
  String _resolveVariable(TemplateVariable variable, _TemplateContext ctx) {
    switch (variable) {
      // Date and time variables
      case TemplateVariable.weekNum:
        return ctx.weekNum.toString();
      case TemplateVariable.date:
        return formatDate(ctx.endDate);
      case TemplateVariable.month:
        return _monthName(ctx.endDate.month);
      case TemplateVariable.year:
        return ctx.endDate.year.toString();
      case TemplateVariable.timestamp:
        return (ctx.endDate.millisecondsSinceEpoch ~/ 1000).toString();

      // Enhanced date variables
      case TemplateVariable.monthNum:
        return ctx.endDate.month.toString().padLeft(2, '0');
      case TemplateVariable.monthName:
        return _monthName(ctx.endDate.month);
      case TemplateVariable.monthNameShort:
        return _monthNameShort(ctx.endDate.month);
      case TemplateVariable.quarter:
        return 'Q${((ctx.endDate.month - 1) ~/ 3) + 1}';
      case TemplateVariable.yearShort:
        return (ctx.endDate.year % 100).toString().padLeft(2, '0');

      // Week variables
      case TemplateVariable.weekStartDate:
        return formatDate(ctx.weekStart);
      case TemplateVariable.weekEndDate:
        return formatDate(ctx.weekEnd);

      // Date range variables
      case TemplateVariable.dateRangeStartDate:
        return formatDate(ctx.dateRangeStart);
      case TemplateVariable.dateRangeEndDate:
        return formatDate(ctx.dateRangeEnd);
      case TemplateVariable.dateRangeDays:
        return ctx.dateRangeDays.toString();
      case TemplateVariable.dateRangeStartShort:
        return _formatDateShort(ctx.dateRangeStart);
      case TemplateVariable.dateRangeEndShort:
        return _formatDateShort(ctx.dateRangeEnd);
      case TemplateVariable.dateRangeMonth:
        return ctx.dateRangeMonth;
      case TemplateVariable.dateRangeCrossMonth:
        return ctx.dateRangeCrossMonth;

      // Format variables
      case TemplateVariable.dateFormatYYYYMMDD:
        return formatDate(ctx.endDate);
      case TemplateVariable.dateFormatDDMMYYYY:
        final day = ctx.endDate.day.toString().padLeft(2, '0');
        final month = ctx.endDate.month.toString().padLeft(2, '0');
        return '$day-$month-${ctx.endDate.year}';
      case TemplateVariable.dateFormatMmmDD:
        final monthShort = _monthNameShort(ctx.endDate.month);
        final day = ctx.endDate.day.toString().padLeft(2, '0');
        return '$monthShort $day';
      case TemplateVariable.timeFormatHHMM:
        final hour = ctx.endDate.hour.toString().padLeft(2, '0');
        final minute = ctx.endDate.minute.toString().padLeft(2, '0');
        return '$hour:$minute';

      // Real date variables
      case TemplateVariable.realDate:
        return formatDate(ctx.now);
      case TemplateVariable.realYear:
        return ctx.now.year.toString();
      case TemplateVariable.realMonth:
        return _monthName(ctx.now.month);
      case TemplateVariable.realMonthNum:
        return ctx.now.month.toString().padLeft(2, '0');
      case TemplateVariable.realYearShort:
        return (ctx.now.year % 100).toString().padLeft(2, '0');
      case TemplateVariable.realWeekNum:
        return ctx.realWeekNum.toString();
      case TemplateVariable.realDay:
        return ctx.now.day.toString().padLeft(2, '0');
      case TemplateVariable.realDayName:
        return _dayName(ctx.now.weekday);
      case TemplateVariable.realDayNameShort:
        return _dayNameShort(ctx.now.weekday);
      case TemplateVariable.realTimestamp:
        return (ctx.now.millisecondsSinceEpoch ~/ 1000).toString();
      case TemplateVariable.realWeekStartDate:
        return formatDate(ctx.realWeekStart);
      case TemplateVariable.realWeekEndDate:
        return formatDate(ctx.realWeekEnd);

      // Real time and datetime variables
      case TemplateVariable.realTime:
        final hour = ctx.now.hour.toString().padLeft(2, '0');
        final minute = ctx.now.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      case TemplateVariable.realTimeWithSeconds:
        final hour = ctx.now.hour.toString().padLeft(2, '0');
        final minute = ctx.now.minute.toString().padLeft(2, '0');
        final second = ctx.now.second.toString().padLeft(2, '0');
        return '$hour:$minute:$second';
      case TemplateVariable.realDateTime:
        return formatDate(ctx.now);
      case TemplateVariable.realDateTimeFull:
        return formatDate(ctx.now);

      // Content statistics
      case TemplateVariable.trackCount:
        return ctx.trackCount.toString();
      case TemplateVariable.sourceCount:
        return ctx.sourceCount.toString();

      // Job source counts (from configuration)
      case TemplateVariable.jobPlaylistCount:
        return ctx.jobPlaylistCount.toString();
      case TemplateVariable.jobArtistCount:
        return ctx.jobArtistCount.toString();
      case TemplateVariable.jobLabelCount:
        return ctx.jobLabelCount.toString();

      // Real content counts (from actual tracks)
      case TemplateVariable.realArtistCount:
        return ctx.realArtistCount.toString();
      case TemplateVariable.realAlbumCount:
        return ctx.realAlbumCount.toString();
      case TemplateVariable.realPlaylistCount:
        return ctx.realPlaylistCount.toString();
      case TemplateVariable.realArtistSourceCount:
        return ctx.realArtistSourceCount.toString();
      case TemplateVariable.realLabelSourceCount:
        return ctx.realLabelCount.toString();

      // Legacy aliases
      case TemplateVariable.playlistCount:
        return ctx.jobPlaylistCount.toString();
      case TemplateVariable.artistCount:
        return ctx.jobArtistCount.toString();
      case TemplateVariable.labelCount:
        return ctx.jobLabelCount.toString();

      // Job and configuration variables
      case TemplateVariable.jobName:
        return ctx.job.name;
      case TemplateVariable.jobNamePretty:
        return ctx.jobNamePretty;
      case TemplateVariable.inputSources:
        return ctx.inputSources;
    }
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  String _monthNameShort(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month];
  }

  String _dayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday];
  }

  String _dayNameShort(int weekday) {
    const names = [
      '',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return names[weekday];
  }

  String _formatDateShort(DateTime date) {
    final monthShort = _monthNameShort(date.month);
    final day = date.day.toString().padLeft(2, '0');
    return '$monthShort $day';
  }
}

/// Internal context holder for template rendering.
class _TemplateContext {
  _TemplateContext({
    required this.job,
    required this.cutoffDate,
    required this.endDate,
    required this.trackCount,
    required this.realArtistCount,
    required this.realAlbumCount,
    required this.realPlaylistCount,
    required this.realArtistSourceCount,
    required this.realLabelCount,
  }) : now = DateTime.now(),
       weekNum = getWeekNumber(endDate),
       dateRangeStart = cutoffDate.add(const Duration(days: 1)),
       dateRangeEnd = endDate {
    // Calculate derived values
    dateRangeDays = dateRangeEnd.difference(dateRangeStart).inDays + 1;

    weekStart = endDate.subtract(Duration(days: endDate.weekday - 1));
    weekEnd = weekStart.add(const Duration(days: 6));

    realWeekNum = getWeekNumber(now);
    realWeekStart = now.subtract(Duration(days: now.weekday - 1));
    realWeekEnd = realWeekStart.add(const Duration(days: 6));

    // Count input sources from job configuration
    jobPlaylistCount = job.inputs.playlists?.length ?? 0;
    jobArtistCount = job.inputs.artists?.length ?? 0;
    jobLabelCount = job.inputs.labels?.length ?? 0;
    sourceCount = jobPlaylistCount + jobArtistCount + jobLabelCount;

    // Build input sources string
    final sources = <String>[];
    if (jobPlaylistCount > 0) {
      sources.add(
        '$jobPlaylistCount playlist${jobPlaylistCount > 1 ? 's' : ''}',
      );
    }
    if (jobArtistCount > 0) {
      sources.add('$jobArtistCount artist${jobArtistCount > 1 ? 's' : ''}');
    }
    if (jobLabelCount > 0) {
      sources.add('$jobLabelCount label${jobLabelCount > 1 ? 's' : ''}');
    }
    inputSources = sources.isEmpty ? 'various sources' : sources.join(', ');

    // Build date range strings
    if (dateRangeStart.month == dateRangeEnd.month) {
      dateRangeMonth =
          '${_monthName(dateRangeStart.month)} ${dateRangeStart.year}';
      dateRangeCrossMonth = dateRangeMonth;
    } else {
      final startMonth = _monthName(dateRangeStart.month);
      final endMonth = _monthName(dateRangeEnd.month);
      dateRangeMonth = '$startMonth - $endMonth ${dateRangeEnd.year}';
      final startShort = _formatDateShort(dateRangeStart);
      final endShort = _formatDateShort(dateRangeEnd);
      dateRangeCrossMonth = '$startShort - $endShort';
    }

    // Build job name pretty
    jobNamePretty = job.name
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  final CrawlJob job;
  final DateTime cutoffDate;
  final DateTime endDate;
  final int trackCount;

  // Real counts from actual tracks
  final int realArtistCount;
  final int realAlbumCount;
  final int realPlaylistCount;
  final int realArtistSourceCount;
  final int realLabelCount;

  final DateTime now;
  final int weekNum;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;

  late final int dateRangeDays;
  late final DateTime weekStart;
  late final DateTime weekEnd;
  late final int realWeekNum;
  late final DateTime realWeekStart;
  late final DateTime realWeekEnd;
  late final int jobPlaylistCount;
  late final int jobArtistCount;
  late final int jobLabelCount;
  late final int sourceCount;
  late final String inputSources;
  late final String dateRangeMonth;
  late final String dateRangeCrossMonth;
  late final String jobNamePretty;

  static String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  static String _formatDateShort(DateTime date) {
    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[date.month]} ${date.day.toString().padLeft(2, '0')}';
  }
}
